defmodule ExOtp.Totp do
  @moduledoc """
  Module for the Time-based One-time Password algorithm.
  """

  alias ExOtp.{Base, Errors}
  alias __MODULE__

  @keys [
    :base,
    interval: 30
  ]

  @enforce_keys [:interval, :base]

  defstruct @keys

  @type t :: %__MODULE__{
          interval: Integer.t(),
          base: Base.t()
        }

  @spec new(integer) :: t()
  def new(interval) do
    %Totp{interval: interval, base: %Base{}}
  end

  @spec validate(t()) :: no_return() | t()
  def validate(%Totp{interval: interval}) when not is_integer(interval) do
    raise Errors.InvalidParam, "interval should be an integer"
  end

  def validate(totp), do: totp

  @spec at(t(), integer, integer) :: String.t()
  def at(%Totp{base: base, interval: interval}, for_time, counter \\ 0)
      when is_integer(for_time) do
    Base.generate_otp(base, (for_time / interval) |> round() |> Kernel.+(counter))
  end

  @spec now(t()) :: String.t()
  def now(%Totp{} = totp) do
    at(totp, DateTime.utc_now() |> DateTime.to_unix())
  end

  # TODO: Change the comparison to be Timing-Attack Safe.
  @spec valid?(t(), String.t(), nil | Datetime.t(), nil | integer) :: boolean
  def valid?(%Totp{} = totp, otp, for_time \\ DateTime.utc_now(), valid_window \\ 0) do
    if valid_window do
      Enum.any?(-valid_window..valid_window, fn index ->
        otp == at(totp, DateTime.to_unix(for_time), index)
      end)
    else
      otp == at(totp, DateTime.to_unix(for_time))
    end
  end
end
