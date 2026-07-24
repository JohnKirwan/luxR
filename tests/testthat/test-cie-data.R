test_that("bundled CIE photopic data match the pinned official table", {
  expect_identical(names(CIE1931), c("lambda", "W"))
  expect_identical(CIE1931$lambda, 360:830)
  expect_true(all(is.finite(CIE1931$W)))
  expect_true(all(CIE1931$W >= 0 & CIE1931$W <= 1))
  expect_identical(CIE1931$lambda[which.max(CIE1931$W)], 555L)
  expect_identical(CIE1931$W[CIE1931$lambda == 430L], 0.0116)
  expect_identical(CIE1931$W[CIE1931$lambda == 555L], 1)
  expect_identical(CIE1931$W[CIE1931$lambda == 770L], 0.00003)

  expect_identical(
    attr(CIE1931, "source_url"),
    "https://files.cie.co.at/CIE_sle_photopic.csv"
  )
  expect_identical(attr(CIE1931, "source_doi"),
                   "10.25039/CIE.DS.dktna2s3")
  expect_identical(attr(CIE1931, "source_md5"),
                   "f389958555461a7d9a7562145e8ca9c0")
  expect_identical(
    attr(CIE1931, "metadata_url"),
    "https://files.cie.co.at/CIE_sle_photopic.csv_metadata.json"
  )
  expect_identical(attr(CIE1931, "metadata_md5"),
                   "b56e625687f5ef8d7403e8867b16e973")
  expect_identical(attr(CIE1931, "retrieval_date"), "2026-07-21")
  expect_identical(attr(CIE1931, "source_standard"), "CIE 018:2019")
  expect_identical(attr(CIE1931, "license"), "CC BY-SA 4.0")
})

test_that("bundled CIE scotopic data match the pinned official table", {
  expect_identical(names(CIE_scotopic), c("lambda", "W"))
  expect_identical(CIE_scotopic$lambda, 380:780)
  expect_true(all(is.finite(CIE_scotopic$W)))
  expect_true(all(CIE_scotopic$W >= 0 & CIE_scotopic$W <= 1))
  expect_identical(CIE_scotopic$lambda[CIE_scotopic$W == 1], 506:508)
  expect_identical(CIE_scotopic$W[CIE_scotopic$lambda == 380L], 0.000589)
  expect_identical(CIE_scotopic$W[CIE_scotopic$lambda == 507L], 1)
  expect_identical(CIE_scotopic$W[CIE_scotopic$lambda == 780L], 1.39e-07)

  expect_identical(
    attr(CIE_scotopic, "source_url"),
    "https://files.cie.co.at/CIE_sle_scotopic.csv"
  )
  expect_identical(attr(CIE_scotopic, "source_doi"),
                   "10.25039/CIE.DS.gr6w4b5g")
  expect_identical(attr(CIE_scotopic, "source_md5"),
                   "3e45714a429d02e5d1f2a752226d7698")
  expect_identical(
    attr(CIE_scotopic, "metadata_url"),
    "https://files.cie.co.at/CIE_sle_scotopic.csv_metadata.json"
  )
  expect_identical(attr(CIE_scotopic, "metadata_md5"),
                   "fdcc3cc42a695bb2c0edacc6da9b084e")
  expect_identical(attr(CIE_scotopic, "retrieval_date"), "2026-07-21")
  expect_identical(attr(CIE_scotopic, "source_standard"), "CIE 018:2019")
  expect_identical(attr(CIE_scotopic, "license"), "CC BY-SA 4.0")
})
