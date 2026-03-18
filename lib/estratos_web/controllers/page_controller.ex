defmodule EstratosWeb.PageController do
  use EstratosWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
