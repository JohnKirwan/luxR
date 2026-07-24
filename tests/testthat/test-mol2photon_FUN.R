test_that("Avogadro's number of photons", {
  expect_equal(
    mol2photon_FUN(1e6, molar_unit="umol"),
    6.02214076e23)
})

test_that("mol2photon_FUN errors on unrecognised molar_unit", {
  expect_error(mol2photon_FUN(1, "photons"),  "[Uu]nrecogni")
  expect_error(mol2photon_FUN(1, "nmol"),     "[Uu]nrecogni")
  expect_error(mol2photon_FUN(1, "banana"),   "[Uu]nrecogni")
})
