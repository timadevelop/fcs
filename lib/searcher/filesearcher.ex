defmodule FileSearcher do
  @callback find(pid :: PID, filename :: String, request :: String) ::
    {:found, count :: Number} | {:not_found}
end
