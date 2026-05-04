defmodule CondorDelSurTest do
  use ExUnit.Case

  # Setup para los test: vuelo con 3 asientos y 2 pasajeros
  defp setup_flight do
    flight = Flight.new(1, "Buenos Aires", "Bariloche", 3)
    flight = Flight.add_passenger(flight, "Juan")
    flight = Flight.add_passenger(flight, "Maria")
    flight
  end

  test "iniciar una reserva sobre un asiento disponible" do
    flight = setup_flight()
    assert {:ok, _flight, reservation} = Flight.make_reservation(flight, 1, 1)
    assert reservation.status == :pending
    assert reservation.seat_id == 1
    assert reservation.passenger_id == 1
  end

  test "intentar reservar un asiento ocupado" do
    flight = setup_flight()
    {:ok, flight, _} = Flight.make_reservation(flight, 1, 1)
    assert {:error, :seat_not_available} = Flight.make_reservation(flight, 2, 1)
  end

  test "confirmar una reserva pendiente" do
    flight = setup_flight()
    {:ok, flight, reservation} = Flight.make_reservation(flight, 1, 1)
    assert {:ok, _flight, confirmed} = Flight.confirm_reservation(flight, reservation.id)
    assert confirmed.status == :confirmed
  end

  test "cancelar una reserva pendiente libera el asiento" do
    flight = setup_flight()
    {:ok, flight, reservation} = Flight.make_reservation(flight, 1, 1)
    assert {:ok, updated_flight} = Flight.cancel_reservation(flight, reservation.id)
    assert updated_flight.reservations[reservation.id].status == :cancelled
    assert updated_flight.seats[1].status == :available
  end

  test "evitar cancelar una reserva ya confirmada" do
    flight = setup_flight()
    {:ok, flight, reservation} = Flight.make_reservation(flight, 1, 1)
    {:ok, flight, _} = Flight.confirm_reservation(flight, reservation.id)
    assert {:error, :reservation_not_pending} = Flight.cancel_reservation(flight, reservation.id)
  end

  test "una reserva expirada libera el asiento" do
    flight = setup_flight()
    {:ok, flight, reservation} = Flight.make_reservation(flight, 1, 1)
    assert {:ok, updated_flight} = Flight.expire_reservation(flight, reservation.id)
    assert updated_flight.reservations[reservation.id].status == :expired
    assert updated_flight.seats[1].status == :available
  end
end
