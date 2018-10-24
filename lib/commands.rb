require 'csv'
require 'json'
require 'redis'

class MetisUtils

  class Help < Etna::Command
    usage 'List this help'

    def execute
      puts 'Commands:'
      Ihg.instance.commands.each do |name,cmd|
        puts cmd.usage
      end
    end
  end

  class Console < Etna::Command
    usage 'Open a console with a connected app instance.'

    def execute
      require 'irb'
      ARGV.clear
      IRB.start
    end

    def setup(config)
      super
    end
  end

  class MetisSummary < Etna::Command

    usage "Take a file/dir scan from Metis and summarize the data.
      *args - arg[0]: input_metis_scan_file\n\n"

    def execute(input_metis_scan_file)
      total_files = 0
      total_size = 0
      File.foreach(input_metis_scan_file).with_index do |line, line_num|

       line = line.split("\t")
       if(
          !line[1].end_with?("/\n") &&
          !line[1].include?("C=M;O=D") &&
          !line[1].include?("C=M;O=A") &&
          !line[1].include?("C=N;O=D") &&
          !line[1].include?("C=N;O=A") &&
          !line[1].include?("C=S;O=D") &&
          !line[1].include?("C=S;O=A") &&
          !line[1].include?("C=D;O=D") &&
          !line[1].include?("C=D;O=A")
        )
          total_size += line[0].to_i
          total_files += 1

          puts "\r#{total_size} bytes"
          print "\033[1A"
        end
      end

      human_readable = total_size / 1024 / 1024 / 1024
      puts "Total data size: #{human_readable}GB (#{total_size} bytes)"
      puts "Total file count: #{total_files}"
    end

    def setup(config)
      super
    end
  end

  class MetisUpdate < Etna::Command
    usage "Loop a csv version of an Metis scre and update the DB as necessary.
      *args - arg[0]: input_metis_clean_csv, arg[1]: output_metis_new_csv\n\n"

    def set_record(key, size)
      @redis.set(
        key,
        {
          size: size,
        }.to_json
      )
    end

    def output_report(total_records, new_records, old_records)
      puts "\r Total: #{total_records}                                         "
      puts "\r New:   #{new_records}                                           "
      puts "\r Old:   #{old_records}                                           "
    end

    def execute(input_metis_clean_csv, output_metis_new_csv)
      total_records = 0
      new_records = 0
      old_records = 0

      input_tsv = CSV.read(input_metis_clean_csv)
      output_csv = CSV.open(output_metis_new_csv, 'w')

      input_tsv.each do |row|
        result = @redis.get(row[1])

        if result.nil?
          set_record(row[1], row[0])
          output_csv << row
          new_records += 1
        else
          old_records += 1
        end

        total_records += 1
        output_report(total_records, new_records, old_records)
        print "\033[3A"

        if total_records%10000 == 0
          output_csv.flush
        end
      end

      output_report(total_records, new_records, old_records)
    end

    def setup(config, *args)
      super
      @redis = Redis.new(db: 1)
    end
  end

  class MetisPrune < Etna::Command
    usage "Take in a Metis tsv scan and output a csv without junk files.
      *args - arg[0]: input_metis_scan_tsv, arg[1]: output_metis_clean_csv\n\n"

    def execute(input_metis_scan_tsv, output_metis_clean_csv)

      output_csv = CSV.open(output_metis_clean_csv, 'w')
      line_count = 0
      CSV.foreach(input_metis_scan_tsv, {col_sep: "\t"}) do |row|
        if(
          !row[1].end_with?("/\n") &&
          !row[1].include?("C=M;O=D") &&
          !row[1].include?("C=M;O=A") &&
          !row[1].include?("C=N;O=D") &&
          !row[1].include?("C=N;O=A") &&
          !row[1].include?("C=S;O=D") &&
          !row[1].include?("C=S;O=A") &&
          !row[1].include?("C=D;O=D") &&
          !row[1].include?("C=D;O=A") &&
          !row[1].include?("index.html")
        )
          output_csv << [row[0], row[1].sub('./', '')]
        end

        line_count += 1
        puts "\r#{line_count} lines                                            "
        print "\033[1A"

        if line_count%10000 == 0
          output_csv.flush
        end
      end

      output_csv.close
    end

    def setup(config)
      super
    end
  end

  class MetisLoad < Etna::Command
    usage "Do and initial load of scanned Metis data into the Redis DB.
      *args - arg[0]: input_metis_scan_csv\n\n"

    def execute(input_metis_scan_csv)
      redis = Redis.new(db: 1)

      CSV.foreach(input_metis_scan_csv) do |row|
        redis.set(
          row[1],
          {
            size: row[0].to_i
          }.to_json
        )
      end
    end

    def setup(config)
      super
    end
  end

  class IhgSummary < Etna::Command
    usage "Take a parsed csv scan file and summarize the size and file count
      *args - arg[0]: input_scan_csv_file\n\n"

    def execute(input_scan_csv_file)
      start_stamp = nil
      end_stamp = nil
      total_files = 0
      total_size = 0

      CSV.foreach(input_scan_csv_file).with_index do |row, index|

        if index == 0
          start_stamp = row[1]
        end

        end_stamp = row[1]
        total_files += 1
        total_size = total_size + row[0].to_i

        puts "\r#{total_size} bytes"
        print "\033[1Av"
      end

      human_readable = total_size / 1024 / 1024 / 1024
      puts "Web scrape started:  #{start_stamp}"
      puts "Web scrape finished: #{end_stamp}"
      puts "Total data size: #{human_readable}GB (#{total_size} bytes)"
      puts "Total file count: #{total_files}"
    end

    def setup(config, *args)
      super
    end
  end

  class IhgPrune < Etna::Command
   usage "Take a scrape file and output a csv of the data.
      *args - arg[0]: 01-fongl-ihg-scrape_[MONTH]_[DATE].log, arg[1]: 02-fongl-ihg-clean_[MONTH]_[DATE].csv\n\n"

    def reset_vars
      @url_matches = false
      @length_matches = false

      @url_str=''
      @length_str=''
    end

    def parse_vars(content_length, url_data)
      size = content_length.split(' ')[1].to_i
      last_scan = "#{url_data.split(' ')[0].sub!('--', '')} #{url_data.split(' ')[1].sub!('--', '')}"
      file = url_data.split(' ')[2]
      "#{size},#{last_scan},#{file}\n"
    end

    def execute(input_scrape_file, output_csv_file)
      url_to_match = 'https://ihg-client.ucsf.edu/fongl/'
      content_length_to_match = 'Content-Length'
      ending_str = 'broken links'

      @url_matches = false
      @length_matches = false

      @url_str=''
      @length_str=''

      output_file = File.open(output_csv_file, 'w')
      File.foreach(input_scrape_file).with_index do |line, line_num|

        if line.include?(url_to_match)
          @url_matches = true
          @url_str = line
        end

        if line.include?(content_length_to_match)
          @length_matches = true
          @length_str = line
        end

        if line == "\n"
          reset_vars
        end

        if @url_matches && @length_matches
          if(
            !@url_str.end_with?("/\n") &&
            !@url_str.include?("C=M;O=D") &&
            !@url_str.include?("C=M;O=A") &&
            !@url_str.include?("C=N;O=D") &&
            !@url_str.include?("C=N;O=A") &&
            !@url_str.include?("C=S;O=D") &&
            !@url_str.include?("C=S;O=A") &&
            !@url_str.include?("C=D;O=D") &&
            !@url_str.include?("C=D;O=A")
          )

            output_file.write(
              parse_vars(@length_str, @url_str)
            )
          end

          reset_vars
        end

        if line_num%1000 == 0
          output_file.flush
        end
      end

      output_file.close
    end

    def setup(config, *args)
      super
    end
  end

  class IhgUpdate < Etna::Command
    usage "Loop a csv version of an IHG scrape and update the DB as necessary.
      *args - arg[0]: 02-fongl-ihg-clean_[MONTH]_[DATE].csv, arg[1]: 03-fongl-ihg-new_[MONTH]_[DATE].csv\n\n"

    def set_record(key, size, last_scan)
      @redis.set(
        key,
        {
          size: size,
          last_scan: last_scan
        }.to_json
      )
    end

    def output_report(total_records, new_records, old_records, update_records)
      puts "\r Total:   #{total_records}                                       "
      puts "\r New:     #{new_records}                                         "
      puts "\r Old:     #{old_records}                                         "
      puts "\r Updated: #{update_records}                                      "
    end

    def execute(input_ihg_clean_csv, output_ihg_new_csv)
      total_records = 0
      new_records = 0
      old_records = 0
      update_records = 0
      url = 'https://ihg-client.ucsf.edu/fongl/'

      input_csv = CSV.read(input_ihg_clean_csv)
      output_csv = CSV.open(output_ihg_new_csv, 'w')

      input_csv.each do |row|

        key = row[2].sub(url, '')
        result = @redis.get(key)

        if result.nil?
          set_record(key, row[0], row[1])
          output_csv << row
          new_records += 1
        else

          result = JSON.parse(result)

          if(
            DateTime.parse(row[1]) !=
            DateTime.parse(result['last_scan'])
          )
            set_record(key, row[0], row[1])
            update_records += 1
          end
           old_records += 1
        end

        total_records += 1
        output_report(total_records, new_records, old_records, update_records)
        print "\033[4A"

        if total_records%10000 == 0
          output_csv.flush
        end
      end

      output_report(total_records, new_records, old_records, update_records)
    end

    def setup(config, *args)
      super
      @redis = Redis.new(db: 0)
    end
  end

  class IhgLoad < Etna::Command

    usage "Do and initial load of scanned IHG data into the Redis DB.
      *args - arg[0]: 02-fongl-ihg-clean_[MONTH]_[DATE].csv\n\n"

    def execute(input_ihg_clean_csv)
      redis = Redis.new(db: 0)
      base_url = 'https://ihg-client.ucsf.edu/fongl/'

      CSV.foreach(input_ihg_clean_csv).with_index do |row, row_num|
        redis.set(
          row[2].sub!(base_url, ''),
          {
            size: row[0].to_i,
            last_scan: row[1]
          }.to_json
        )
      end
    end

    def setup(config)
      super
    end
  end
end
