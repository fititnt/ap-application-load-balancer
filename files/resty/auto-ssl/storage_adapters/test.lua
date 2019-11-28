-- https://stevedonovan.github.io/ldoc/manual/doc.md.html


--- solve a quadratic equation.
-- @param a first coeff
-- @param b second coeff
-- @param c third coeff
-- @return first root, or nil
-- @return second root, or imaginary root error
function solve (a,b,c)
    local disc = b^2 - 4*a*c
    if disc < 0 then
        return nil,"imaginary roots"
    else
       disc = math.sqrt(disc)
       return (-b + disc)/2*a,
              (-b - disc)/2*a
    end
end

