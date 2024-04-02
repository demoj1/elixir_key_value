defmodule KeyValue.Distributor do
  @moduledoc """

    Модуль обработки запросов к АПИ для хранилища key-value
    По следующим правилам:

     # get - method: GET, params: ["key"] -> return 200 and JSON | 404
     # create - method: POST, params: ["key", "value", "ttl"] -> return 201 | 409 if key is created
     # update - method: PUT, params: ["key", "value", "ttl"] -> return 200 or 204 | 404
     # delete - method: DELETE, params: ["key"] -> 200 or 204 | 404
  """
  alias KeyValue.Storage

  @doc """

  """
  # Сохранение ключа и значения с учётом срока жизни записи установленой параметром ttl в секундах
  # Если значение с данным ключом есть, вернёт ошибку 409
  @spec to_storage(any(), any()) :: {200 | 201 | 204 | 404 | 409} | {200, [list()] | map()}
  def to_storage("POST", %{"key" => key, "value" => value, "ttl" => ttl}) do
    {ttl,_} = Integer.parse(ttl)

    case Storage.insert(key, value, ttl) do
      true -> {201}
      _ -> {409}
    end
  end

  # Возвращает Map ключа и значения, которые были при создании
  # Если записи с ключом нет, то возвращает 404
  def to_storage("GET", %{"key" => key}) do
    case result = Storage.get(key) do
      :error -> {404}
      _ -> {200, result}
    end
  end

  # Возвращает List всех записей в хранилище
  def to_storage("GET", %{}) do
    result = Storage.get_all()
    result |> IO.inspect(label: :result)

    case result do
      {:error, _} -> {404}
      _ -> {200, result}
    end
  end

  # Функция изменения параметров строки
  # Если записи нет, вернёт 404
  def to_storage("PUT", %{"key" => key, "value" => value, "ttl" => ttl}) do
    {ttl,_} = Integer.parse(ttl)

    case Storage.update(key, value, ttl) do
      :ok -> {204}
      _ -> {404}
    end
  end

  # Удаление записи по ключу,
  # если ключа нет, вернёт 404
  def to_storage("DELETE", %{"key" => key}) do
      case Storage.check_and_delete(key) do
        :ok -> {200}
        _ -> {404}
      end
  end

  # Если метод и значения не определёны, то ввозвращаем 404
  # И выводит в консоль список просроченных ключей,
  # использовал для просмотра ключей, которые просрочены
  def to_storage(_, _) do
    Storage.get_ttl_expire() |> IO.inspect(label: :expired_keys)
    {404}
  end

end
