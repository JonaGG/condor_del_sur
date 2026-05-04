# Cóndor del Sur — Reserva concurrente de asientos

Sistema de reserva de asientos para una aerolínea, implementado en Elixir con procesos manuales (sin OTP).

---

## Cómo compilar

```bash
mix compile
```

---

## Cómo correr la demo

```bash
iex -S mix
```

```elixir
c("demo.exs")
Demo.run
```

La demo muestra:
- 100 pasajeros compitiendo por 10 asientos al mismo tiempo
- Resolución correcta de conflictos (solo 1 pasajero por asiento)
- Un caso de cancelación antes de confirmar
- Un caso de expiración automática a los 30 segundos
- Estado final claro del vuelo

---

## Cómo correr los tests

```bash
mix test
```

---
## Diseño del sistema

### Modelado de dominio
El sistema se modela con 4 structs:
- `Passenger` — representa un pasajero registrado en el sistema
- `Seat` — representa un asiento con su estado (`:available`, `:reserved`, `:confirmed`)
- `Reservation` — conecta un pasajero con un asiento, tiene su propio estado (`:pending`, `:confirmed`, `:cancelled`, `:expired`)
- `Flight` — contiene el estado completo del vuelo: asientos, pasajeros y reservas

### Procesos con estado
- **`FlightServer`** — proceso central registrado como `:flight_server`. Mantiene el estado del vuelo en un loop recursivo. Serializa todas las operaciones garantizando que no haya race conditions.
- **`AuditServer`** — proceso registrado como `:audit_server`. Mantiene un log de eventos del sistema.

### Procesos para tareas puntuales
- **`ExpirationProcess`** — nace cuando se crea una reserva, espera 30 segundos y la expira si no fue confirmada. Hace su trabajo y muere.

### Procesos cliente
- **`PassengerProcess`** — múltiples instancias corren concurrentemente, cada una representa un pasajero compitiendo por un asiento. No tienen estado propio ni loop.

### Uso de `register` y `monitor`
- **`register`**: `FlightServer` se registra como `:flight_server` y `AuditServer` como `:audit_server`, permitiendo que cualquier proceso les envíe mensajes por nombre sin conocer su PID.
- **`monitor`**: `AuditServer` monitorea a `FlightServer` con `Process.monitor/1`. Si `FlightServer` cae, `AuditServer` recibe un mensaje `{:DOWN, ...}` y registra el evento crítico.

---

## Procesos principales

### FlightServer
Proceso central del sistema. Mantiene el estado completo del vuelo (`%Flight{}`) en un loop recursivo. Serializa todas las operaciones sobre asientos y reservas, evitando race conditions. Registrado con el nombre `:flight_server`.

### AuditServer
Proceso auxiliar de auditoría. Recibe mensajes de log desde `FlightServer` y los imprime en consola. Monitorea a `FlightServer` — si cae, registra un evento crítico. Registrado con el nombre `:audit_server`.

### PassengerProcess
Procesos cliente. Cada instancia representa un pasajero que intenta reservar un asiento. Múltiples instancias corren concurrentemente y compiten por los mismos recursos. Soporta tres comportamientos: `:confirm`, `:cancel`, `:expire`.

### ExpirationProcess
Proceso para tarea puntual. Nace cuando se crea una reserva, duerme 30 segundos y expira la reserva si no fue confirmada ni cancelada. No tiene loop — hace su trabajo y muere.

---

## FlightClient
No es un proceso. Es un módulo helper con funciones que facilitan la comunicación con `FlightServer` — envían mensajes y esperan la respuesta. Útil para interactuar con el sistema desde `iex` o desde la demo.

---
## Uso de `register` y `monitor`

**`register`**: `FlightServer` se registra con `:flight_server` y `AuditServer` con `:audit_server`. Esto permite que cualquier proceso les mande mensajes por nombre sin necesitar su PID.

**`monitor`**: `AuditServer` monitorea a `FlightServer`. Si `FlightServer` cae, `AuditServer` recibe un mensaje `{:DOWN, ...}` y registra el evento crítico.

---
## Estructura del proyecto

```
lib/
  audit_server.ex       # Proceso de auditoría
  expiration_process.ex # Proceso de expiración automática
  flight.ex             # Struct Flight y lógica de dominio
  flight_client.ex      # Helper para comunicarse con FlightServer
  flight_server.ex      # Proceso central con estado del vuelo
  passenger.ex          # Struct Passenger
  passenger_process.ex  # Procesos cliente (pasajeros)
  reservation.ex        # Struct Reservation
  seat.ex               # Struct Seat
demo.exs                # Demo reproducible por consola
README.md
test/
  condor_del_sur_test.exs  # Tests mínimos de dominio
```