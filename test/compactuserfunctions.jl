facts("Cannonical measurement") do
  probability = [0.05, 0.1, 0.25, 0.3, 0.01, 0.20, 0.04, 0.05]
  vset = VertexSet([[1, 4], [2, 3, 5], [6], [7, 8]])
  result = [0.35, 0.36, 0.2, 0.09]
  @fact measurement_nonmoralized(probability, vset) --> result

  state = [1/6 1.0 1/6; 1. 2/3 1im; 1/6 -1im 1/6]
  vset = VertexSet([[1, 3], [2]])
  @fact measurement_nonmoralized(state, vset) --> roughly([1./3, 2./3])
  @fact_throws AssertionError measurement_nonmoralized(eye(2)/2., vset)
  @fact_throws AssertionError measurement_nonmoralized([1./2, 1./3, 1./6, 0.], vset)

end

facts("Initial states creation") do
  vset = VertexSet([[1], [2, 3, 4], [5, 6, 7], [8, 9]])
  @fact init_nonmoralized(vset[[1, 3, 4]], vset) --> roughly(spdiagm([1./3, 0, 0, 0, 1./9, 1./9, 1./9, 1./6, 1./6]))
  A1 = ones(Complex128, 1, 1)/4
  A2 = [ 1/5+0im 0 1/5; 0 1/10 0 ; 1/5 0 1/5 ]
  A3 = [0.125 -0.125+0im; -0.125 0.125]
  dict = Dict(vset[1] =>A1, vset[3] =>A2, vset[4] =>A3 )
  @fact init_nonmoralized(dict, vset) -->
        sparse([ 0.25+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im     0.0+0.0im     0.0+0.0im
                0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im     0.0+0.0im     0.0+0.0im
                0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im     0.0+0.0im     0.0+0.0im
                0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im     0.0+0.0im     0.0+0.0im
                0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.2+0.0im  0.0+0.0im  0.2+0.0im     0.0+0.0im     0.0+0.0im
                0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.1+0.0im  0.0+0.0im     0.0+0.0im     0.0+0.0im
                0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.2+0.0im  0.0+0.0im  0.2+0.0im     0.0+0.0im     0.0+0.0im
                0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im   0.125+0.0im  -0.125+0.0im
                0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  0.0+0.0im  -0.125+0.0im   0.125+0.0im])

  dictwrong = Dict(vset[1] =>A2, vset[3] =>A2, vset[4] =>A3 )
  @fact_throws AssertionError init_nonmoralized(vertices(VertexSet([[1, 2, 3], [4, 5]])), vset)
  @fact_throws AssertionError init_nonmoralized(dictwrong, vset)
end
