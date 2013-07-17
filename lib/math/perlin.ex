defmodule Math.Perlin do
  use Bitwise

  @octaves 4
  @persistence 0.25

  def noise_2d(x, y) do
    layer_noise(x, y, 1, a_prime_list(), 0) 
  end

  defp layer_noise(_x, _y, @octaves, _prime_list, acc)  do
    acc
  end

  defp layer_noise(x, y, i, [primes | rest], acc) do
    frequency = 2 * i
    amplitude = @persistence * i
    total = acc + interpolated_noise(x * frequency, y * frequency, primes) * amplitude
    layer_noise(x, y, i + 1, rest, total)
  end

  defp a_prime_list do
    [{15731, 789221, 1376312589}, {12343, 508919, 11037269701}, {24443, 800011, 22801761629}, {31859, 814643, 25191865613}, {64081, 999983, 27591442693}]
  end

  defp interpolated_noise(x, y, primes) do
    int_x = trunc(x)
    fractional_x = x - int_x
    int_y = trunc(y)
    fractional_y = y - int_y
    v1 = smoothed_noise(int_x, int_y, primes)
    v2 = smoothed_noise(int_x + 1, int_y, primes)
    v3 = smoothed_noise(int_x, int_y + 1, primes)
    v4 = smoothed_noise(int_x + 1, int_y + 1, primes)
    i1 = cosine_interpolate(v1, v2, fractional_x)
    i2 = cosine_interpolate(v3, v4, fractional_x)
    cosine_interpolate(i1 , i2 , fractional_y)
  end

  defp smoothed_noise(x, y, primes) do
    corners = ( randish(x-1, y-1, primes) + randish(x+1, y-1, primes) + randish(x-1, y+1, primes) + randish(x+1, y+1, primes) ) / 16
    sides   = ( randish(x-1, y, primes) + randish(x+1, y, primes) + randish(x, y-1, primes) + randish(x, y+1, primes) ) /  8
    center  = randish(x, y, primes) / 4
    corners + sides + center
  end

  defp cosine_interpolate(a, b, x) do
    ft = x * 3.1415927
    f = (1 - :math.cos(ft)) * 0.5
    a * (1-f) + b * f
  end
  
  defp randish(x, y, {p1, p2, p3}) do
    a = x + y * 57
    b = bsl(a, 13)
    c = bxor(b, a)
    d = :erlang.trunc(c * (c * c * p1 + p2) + p3)
    e = 0x7FFFFFFF
    f = d &&& e
    1.0 - f / 1073741824.0
  end

end