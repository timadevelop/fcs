defmodule FileSearcher do
  @callback find(filename :: String, request :: String) ::
    {:ok, line :: String, request :: String} | :not_found
end
