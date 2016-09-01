defmodule Oauth do
  def sign(verb, url, params, consumer_key, consumer_secret, token \\ nil, token_secret \\ nil) do
    params = make_params(params, consumer_key, token)
    sig = get_signature(verb, url, params, consumer_secret, token_secret)
    [{"oauth_signature", sig} | params]
  end

  def as_header(signed_params) do
    {oauth_params, other_params} = Enum.partition(signed_params, &is_oauth?/1)
    {{"Authorization", "OAuth " <> header_string(oauth_params)}, other_params}
  end

  defp make_params(params, consumer_key, token) do
    nonce = :crypto.strong_rand_bytes(32) |> Base.encode64

    {mega, sec, _} = :os.timestamp
    timestamp = (mega * 1_000_000) + sec

    [{"oauth_consumer_key", consumer_key},
      {"oauth_nonce", nonce},
      {"oauth_signature_method", "HMAC-SHA1"},
      {"oauth_timestamp", timestamp},
      {"oauth_version", "1.0"}
    ]
    ++ token_param(token) ++ params
  end

  defp token_param(nil), do: []
  defp token_param(v), do: [{"oauth_token", v}]

  defp get_signature(verb, url, params, consumer_secret, token_secret) do
    key = [consumer_secret, token_secret] |> Enum.map_join("&", &uri_encode/1)

    uri = URI.parse(url)
    url = %{uri | query: nil, host: String.downcase(uri.host)}
    query_params = parse_query(uri.query)

    params_string =
      (params ++ query_params)
      |> Enum.map(&uri_encode/1) |> Enum.sort |> Enum.map_join("&", &kv_to_string/1)

    data = [String.upcase(verb), url, params_string] |> Enum.map_join("&", &uri_encode/1)

    :crypto.hmac(:sha, key, data)
    |> Base.encode64
  end

  defp uri_encode(nil), do: ""
  defp uri_encode({k, v}), do: {uri_encode(k), uri_encode(v)}
  defp uri_encode(s) when is_binary(s), do: s |> URI.encode(&URI.char_unreserved?/1)
  defp uri_encode(x), do: x |> to_string() |> uri_encode()

  defp parse_query(nil), do: []
  defp parse_query(q), do: q |> URI.query_decoder() |> Enum.into([])

  defp kv_to_string({k, v}), do: "#{k}=#{v}"

  defp is_oauth?({k, _v}), do: String.starts_with?(k, "oauth_")

  defp header_string(x), do: x |> Enum.map_join(", ", &encode_header/1)

  defp encode_header(x), do: x |> uri_encode() |> kv_to_string_header()

  defp kv_to_string_header({k, v}), do: ~s(#{k}="#{v}")
end
