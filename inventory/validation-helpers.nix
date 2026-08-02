{ lib }:

{
  checkEmpty = message: failures: {
    valid = failures == [ ];
    message = "${message}: ${lib.concatStringsSep ", " failures}";
  };

  assertChecks = checks: value:
    lib.foldr
      (check: result: assert lib.assertMsg check.valid check.message; result)
      value
      checks;
}
