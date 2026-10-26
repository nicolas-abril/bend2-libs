# gralha-coverage

Analytic area coverage: line lists in pixel space are scan-converted with a
winding count on a few sub-scanlines per row (exact span extents in x, so
the fill rule holds where contours overlap) into a sparse quadtree mask.

    import gralha-coverage@0.1.0.1/cover.bend as Cov

Main entry points: `CovLine`, `CovMask`, `mask.none`, `mask.at.in`,
`mask.uniform`.

Depends on: gralha-text-scan. Tests: `tests/` (run each from this directory).
