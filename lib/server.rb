class MetisUtils
  class Server < Etna::Server

    # Root path.
    get '/' do
      erb_view(:index)
    end

    def initialize(config)
      super
    end
  end
end
