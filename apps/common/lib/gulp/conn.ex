defmodule Gulp.Conn do
  # @type adapter         :: {module, term}
  @type assigns         :: %{atom => any}
  # @type before_send     :: [(t -> t)]
  @type response_handlers     :: [(t -> t)]
  @type body            :: iodata | nil
  @type cookies         :: %{binary => binary}
  @type halted          :: boolean
  @type headers         :: [{binary, binary}]
  # @type host            :: binary
  # @type int_status      :: non_neg_integer | nil
  # @type owner           :: pid
  @type method          :: binary
  # @type param           :: binary | %{binary => param} | [param]
  # @type params          :: %{binary => param}
  # @type peer            :: {:inet.ip_address, :inet.port_number}
  # @type port_number     :: :inet.port_number
  # @type query_string    :: String.t
  @type resp_cookies    :: %{binary => %{}}
  # @type scheme          :: :http | :https
  # @type secret_key_base :: binary | nil
  # @type segments        :: [binary]
  # @type state           :: :unset | :set | :file | :chunked | :sent
  # @type status          :: atom | int_status

  @type t :: %__MODULE__{
                url: binary,
                req_body: body,
                response_handlers: response_handlers,
                adapter_opts: [],
            # adapter:         adapter,
            assigns:         assigns,
            # before_send:     before_send,
            # body_params:     params | Unfetched.t,
            # cookies:         cookies | Unfetched.t,
            # host:            host,
            method:          method,
            # owner:           owner,
            # params:          params | Unfetched.t,
            # path_info:       segments,
            # port:            :inet.port_number,
            private:         assigns,
            # query_params:    params | Unfetched.t,
            # query_string:    query_string,
            # peer:            peer,
            # remote_ip:       :inet.ip_address,
            # req_cookies:     cookies | Unfetched.t,
            req_headers:     headers,
            # request_path:    binary,
            resp_body:       body,
            resp_cookies:    resp_cookies,
            resp_headers:    headers,
            # scheme:          scheme,
            # script_name:     segments,
            # secret_key_base: secret_key_base,
            # state:           state,
            # status:          int_status
          }

defstruct [url: "",
            req_body: nil,
            response_handlers: [],
            adapter_opts: [],
            # adapter:         {Plug.Conn, nil},
            assigns:         %{},
            # before_send:     [],
            # body_params:     %Unfetched{aspect: :body_params},
            # cookies:         %Unfetched{aspect: :cookies},
            halted:          false,
            # host:            "www.example.com",
            method:          "GET",
            # owner:           nil,
            # params:          %Unfetched{aspect: :params},
            # path_info:       [],
            # port:            0,
            private:         %{},
            # query_params:    %Unfetched{aspect: :query_params},
            # query_string:    "",
            # peer:            nil,
            # remote_ip:       nil,
            # req_cookies:     %Unfetched{aspect: :cookies},
            req_headers:     [],
            # request_path:    "",
            resp_body:       nil,
            resp_cookies:    %{},
            resp_headers:    [{"cache-control", "max-age=0, private, must-revalidate"}],
            # scheme:          :http,
            # script_name:     [],
            # secret_key_base: nil,
            # state:           :unset,
            # status:          nil
          ]

  alias Gulp.Conn

  def register_response_handler(%Conn{response_handlers: response_handlers} = conn, callback)
      when is_function(callback, 1) do
    %{conn | response_handlers: [callback|response_handlers]}
  end

  @spec halt(t) :: t
  def halt(%Conn{} = conn) do
    %{conn | halted: true}
  end

  def run_response_handlers(%Conn{response_handlers: response_handlers} = conn) do
    conn = Enum.reduce response_handlers, conn, &(&1.(&2))
  end


end
