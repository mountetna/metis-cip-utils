require 'csv'
require 'json'
require 'find'
require 'digest/md5'
require 'redis'

class MetisUtils

  class Help < Etna::Command
    usage "List this help.\n\n"

    def execute
      puts 'Commands:'
      MetisUtils.instance.commands.each do |name, cmd|
        puts cmd.usage
      end
    end
  end

  class Console < Etna::Command
    usage "Open a console with a connected app instance.\n\n"

    def execute
      require 'irb'
      ARGV.clear
      IRB.startredis = Redis.new(db: redis_db_index)
    end

    def setup(config)
      super
    end
  end

  class ProcessChecksumFiles < Etna::Command
    usage "Scan for 'md5checksum.txt' files and turn into a CSV.
       * args - arg[0]: directory, arg[1]: output_file.csv\n\n"

    def execute(directory, output_file)
      if !File.directory?(directory)
        puts "'#{directory}' is not a directory."
        exit 1
      end

      output_csv = CSV.open(output_file, 'w')

      Find.find(directory) do |path|
        if path =~ /md5checksum\.txt/

          path.slice!(directory)
          path.slice!('md5checksum.txt')

          File.open(directory+path+'md5checksum.txt').each do |line|
            line.slice!("\n")
            line = line.split(' ')
            output_csv << [nil, "#{path}#{line[1]}", line[0]]
          end
        end
      end

      output_csv.close
    end

    def setup(config, *args)
      super
    end
  end

  class Summary < Etna::Command
    usage "Loop a scan file counting it's files and total size.
       * args - arg[0]: scan_file.csv\n\n"

    def execute(scan_file)
      total_count = 0
      total_size = 0
      CSV.foreach(scan_file) do |row|
        total_count += 1
        total_size += row[0].to_i
      end

      puts "Summary of counts from scan #{scan_file}:"

      puts "#{total_count} files."
      puts "#{total_size} bytes."
    end

    def setup(config, *args)
      super
    end
  end

  class Diff < Etna::Command
    usage "Compare two scans from two Redis DBs.
       * args - arg[0]: redis_db_index_1, arg[1]: redis_db_index_2, arg[3]: \
diff_file.csv\n\n"

    def execute(redis_db_index_1, redis_db_index_2, diff_file)
      redis_a = Redis.new(db: redis_db_index_1)
      redis_b = Redis.new(db: redis_db_index_2)

      new_files = 0
      new_size = 0
      new_list = []

      redis_a_size = redis_a.dbsize
      redis_b_size = redis_b.dbsize

      redis_b.keys.each do |b_key|
        if !redis_a.exists(b_key)
          file_data = JSON.parse(redis_b.get(b_key))

          new_files += 1
          new_size += file_data['size'].to_i
          new_list.push([file_data['size'], b_key, file_data['md5']])
        end
      end

      CSV.open(diff_file, 'w') do |csv|
        new_list.each do |row|
          csv << row
        end
      end

      puts "Summary of diff between redis dbs #{redis_db_index_1} and \
#{redis_db_index_2}:"

      puts "#{redis_a_size} keys in redis db #{redis_db_index_1}."
      puts "#{redis_b_size} keys in redis db #{redis_db_index_2}."
      puts "#{new_files} diff files in redis db #{redis_db_index_2}."
      puts "#{new_size} bytes diff in redis db #{redis_db_index_2}."
    end

    def setup(config, *args)
      super
    end
  end

  class Update < Etna::Command
    usage "Update a Redis DB with a scan file.
       * args - arg[0]: redis_db_index, arg[1]: input_scan_file.csv\n\n"

    def confirm(*args)
      print(*args)
      STDIN.gets.chomp
    end

    def execute(redis_db_index, input_scan_file, prefix)

      if !File.file?(input_scan_file)
        puts "'#{input_scan_file}' is not a file."
        exit 1
      end

      scan_data = CSV.read(input_scan_file)
      new_files = 0
      new_size = 0
      files_wo_hashes = 0
      file_md5_miss = 0
      start_time = Time.now.getutc
      redis = Redis.new(db: redis_db_index)

      if redis.randomkey != nil
        if confirm("The redis db is not empty, continue? [y/n] ") != 'y'
          puts 'Exiting without doing anything.'
          exit 0
        end
      end

      scan_data.each_index do |row_num|

        row = scan_data[row_num]
        row[1].slice!('./')
        row[1].slice!(prefix) if !prefix.nil?

        if !redis.exists(row[1])
          new_files += 1
          new_size += row[0].to_i

          file_data = {size: row[0]}
          file_data['md5'] = row[2] if row[2] != '' && !row[2].nil?
          redis.set(row[1], file_data.to_json)
          next
        end

        file_data = JSON.parse(redis.get(row[1]))

        if !file_data.key?('md5')
          files_wo_hashes += 1

          file_data = {size: row[0]}
          file_data['md5'] = row[2] if row[2] != '' && !row[2].nil?
          redis.set(row[1], file_data.to_json)
          next
        end

        if file_data['md5'] != row[2]
          file_md5_miss += 1
          puts "md5 mismatch:#{row[1]}, db:#{file_data['md5']}, scan:#{row[2]}"
        end
      end

      puts "Summary of update to redis db #{redis_db_index} from scan \
#{input_scan_file}:"

      puts "#{new_files} new files."
      puts "#{new_size} new bytes."
      puts "#{files_wo_hashes} files do not have md5 hashes."
      puts "#{file_md5_miss} files have mismatched md5 hashes."
      puts "Update completed in (#{Time.now.getutc - start_time}) seconds."
    end

    def setup(config, *args)
      super
    end
  end

  # Unfortunately, this command is a memory hog. On large files and directories
  # this will choke due to memory restrictions. The shell script
  # bin/metis_scan.sh will perform the same function without choking. I am
  # leaving this script here as an exmaple of how to do the scan and hash with
  # Ruby.
  class Scan < Etna::Command
    usage "Scan files in a directory. Extract full path name, size, and hash.
       * args - arg[0]: directory, arg[1]: output_scan_file.csv\n\n"

    def execute(directory, output_scan_file)

      if !File.directory?(directory)
        puts "'#{directory}' is not a directory."
        exit 1
      end

      output_scan_csv = CSV.open(output_scan_file, 'w')
      total_size = 0
      total_files = 0
      start_time = Time.now.getutc

      Find.find(directory) do |path|
        if File.file?(path)
          size = File.size(path)
          digest = Digest::MD5.hexdigest(File.read(path))

          output_scan_csv << [size, path, digest]
          output_scan_csv.flush if total_files%10 == 0

          total_size += size
          total_files += 1
        end
      end

      output_scan_csv.close

      puts "Scan summary of #{directory}:"

      puts "#{total_files} files."
      puts "#{total_size} bytes."
      puts "Scan completed in (#{Time.now.getutc - start_time}) seconds."
    end

    def setup(config, *args)
      super
    end
  end
end
