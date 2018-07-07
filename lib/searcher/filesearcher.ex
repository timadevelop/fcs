defmodule FileSearcher do
  @callback find(pid :: PID, filename :: String, request :: String) ::
    {:ok, line :: String, request :: String} | :not_found
end
