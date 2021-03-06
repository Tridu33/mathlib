/-
Copyright (c) 2020 Joseph Myers. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Joseph Myers.
-/
import analysis.normed_space.real_inner_product
import analysis.normed_space.add_torsor
import linear_algebra.affine_space.finite_dimensional
import linear_algebra.affine_space.independent
import tactic.interval_cases

noncomputable theory
open_locale big_operators
open_locale classical
open_locale real

/-!
# Euclidean spaces

This file makes some definitions and proves geometrical results about
real inner product spaces and Euclidean affine spaces.  Results about
real inner product spaces that involve the norm and inner product but
not angles generally go in `analysis.normed_space.real_inner_product`.

## Implementation notes

To declare `P` as the type of points in a Euclidean affine space with
`V` as the type of vectors, use `[inner_product_space V] [metric_space P]
[normed_add_torsor V P]`.  This works better with `out_param` to make
`V` implicit in most cases than having a separate type alias for
Euclidean affine spaces.

Rather than requiring Euclidean affine spaces to be finite-dimensional
(as in the definition on Wikipedia), this is specified only for those
theorems that need it.

## References

* https://en.wikipedia.org/wiki/Euclidean_space

-/

namespace inner_product_geometry
/-!
### Geometrical results on real inner product spaces

This section develops some geometrical definitions and results on real
inner product spaces, where those definitions and results can most
conveniently be developed in terms of vectors and then used to deduce
corresponding results for Euclidean affine spaces.
-/

variables {V : Type*} [inner_product_space V]

/-- The undirected angle between two vectors. If either vector is 0,
this is π/2. -/
def angle (x y : V) : ℝ := real.arccos (inner x y / (∥x∥ * ∥y∥))

/-- The cosine of the angle between two vectors. -/
lemma cos_angle (x y : V) : real.cos (angle x y) = inner x y / (∥x∥ * ∥y∥) :=
real.cos_arccos (abs_le.mp (abs_inner_div_norm_mul_norm_le_one x y)).1
                (abs_le.mp (abs_inner_div_norm_mul_norm_le_one x y)).2

/-- The angle between two vectors does not depend on their order. -/
lemma angle_comm (x y : V) : angle x y = angle y x :=
begin
  unfold angle,
  rw [inner_comm, mul_comm]
end

/-- The angle between the negation of two vectors. -/
@[simp] lemma angle_neg_neg (x y : V) : angle (-x) (-y) = angle x y :=
begin
  unfold angle,
  rw [inner_neg_neg, norm_neg, norm_neg]
end

/-- The angle between two vectors is nonnegative. -/
lemma angle_nonneg (x y : V) : 0 ≤ angle x y :=
real.arccos_nonneg _

/-- The angle between two vectors is at most π. -/
lemma angle_le_pi (x y : V) : angle x y ≤ π :=
real.arccos_le_pi _

/-- The angle between a vector and the negation of another vector. -/
lemma angle_neg_right (x y : V) : angle x (-y) = π - angle x y :=
begin
  unfold angle,
  rw [←real.arccos_neg, norm_neg, inner_neg_right, neg_div]
end

/-- The angle between the negation of a vector and another vector. -/
lemma angle_neg_left (x y : V) : angle (-x) y = π - angle x y :=
by rw [←angle_neg_neg, neg_neg, angle_neg_right]

/-- The angle between the zero vector and a vector. -/
@[simp] lemma angle_zero_left (x : V) : angle 0 x = π / 2 :=
begin
  unfold angle,
  rw [inner_zero_left, zero_div, real.arccos_zero]
end

/-- The angle between a vector and the zero vector. -/
@[simp] lemma angle_zero_right (x : V) : angle x 0 = π / 2 :=
begin
  unfold angle,
  rw [inner_zero_right, zero_div, real.arccos_zero]
end

/-- The angle between a nonzero vector and itself. -/
@[simp] lemma angle_self {x : V} (hx : x ≠ 0) : angle x x = 0 :=
begin
  unfold angle,
  rw [←inner_self_eq_norm_square, div_self (λ h, hx (inner_self_eq_zero.1 h)),
      real.arccos_one]
end

/-- The angle between a nonzero vector and its negation. -/
@[simp] lemma angle_self_neg_of_nonzero {x : V} (hx : x ≠ 0) : angle x (-x) = π :=
by rw [angle_neg_right, angle_self hx, sub_zero]

/-- The angle between the negation of a nonzero vector and that
vector. -/
@[simp] lemma angle_neg_self_of_nonzero {x : V} (hx : x ≠ 0) : angle (-x) x = π :=
by rw [angle_comm, angle_self_neg_of_nonzero hx]

/-- The angle between a vector and a positive multiple of a vector. -/
@[simp] lemma angle_smul_right_of_pos (x y : V) {r : ℝ} (hr : 0 < r) :
  angle x (r • y) = angle x y :=
begin
  unfold angle,
  rw [inner_smul_right, norm_smul, real.norm_eq_abs, abs_of_nonneg (le_of_lt hr), ←mul_assoc,
      mul_comm _ r, mul_assoc, mul_div_mul_left _ _ (ne_of_gt hr)]
end

/-- The angle between a positive multiple of a vector and a vector. -/
@[simp] lemma angle_smul_left_of_pos (x y : V) {r : ℝ} (hr : 0 < r) :
  angle (r • x) y = angle x y :=
by rw [angle_comm, angle_smul_right_of_pos y x hr, angle_comm]

/-- The angle between a vector and a negative multiple of a vector. -/
@[simp] lemma angle_smul_right_of_neg (x y : V) {r : ℝ} (hr : r < 0) :
  angle x (r • y) = angle x (-y) :=
by rw [←neg_neg r, neg_smul, angle_neg_right, angle_smul_right_of_pos x y (neg_pos_of_neg hr),
       angle_neg_right]

/-- The angle between a negative multiple of a vector and a vector. -/
@[simp] lemma angle_smul_left_of_neg (x y : V) {r : ℝ} (hr : r < 0) :
  angle (r • x) y = angle (-x) y :=
by rw [angle_comm, angle_smul_right_of_neg y x hr, angle_comm]

/-- The cosine of the angle between two vectors, multiplied by the
product of their norms. -/
lemma cos_angle_mul_norm_mul_norm (x y : V) : real.cos (angle x y) * (∥x∥ * ∥y∥) = inner x y :=
begin
  rw cos_angle,
  by_cases h : (∥x∥ * ∥y∥) = 0,
  { rw [h, mul_zero],
    cases eq_zero_or_eq_zero_of_mul_eq_zero h with hx hy,
    { rw norm_eq_zero at hx,
      rw [hx, inner_zero_left] },
    { rw norm_eq_zero at hy,
      rw [hy, inner_zero_right] } },
  { exact div_mul_cancel _ h }
end

/-- The sine of the angle between two vectors, multiplied by the
product of their norms. -/
lemma sin_angle_mul_norm_mul_norm (x y : V) : real.sin (angle x y) * (∥x∥ * ∥y∥) =
    real.sqrt (inner x x * inner y y - inner x y * inner x y) :=
begin
  unfold angle,
  rw [real.sin_arccos (abs_le.mp (abs_inner_div_norm_mul_norm_le_one x y)).1
                      (abs_le.mp (abs_inner_div_norm_mul_norm_le_one x y)).2,
      ←real.sqrt_mul_self (mul_nonneg (norm_nonneg x) (norm_nonneg y)),
      ←real.sqrt_mul' _ (mul_self_nonneg _), pow_two,
      real.sqrt_mul_self (mul_nonneg (norm_nonneg x) (norm_nonneg y)), inner_self_eq_norm_square,
      inner_self_eq_norm_square],
  by_cases h : (∥x∥ * ∥y∥) = 0,
  { rw [(show ∥x∥ * ∥x∥ * (∥y∥ * ∥y∥) = (∥x∥ * ∥y∥) * (∥x∥ * ∥y∥), by ring), h, mul_zero, mul_zero,
        zero_sub],
    cases eq_zero_or_eq_zero_of_mul_eq_zero h with hx hy,
    { rw norm_eq_zero at hx,
      rw [hx, inner_zero_left, zero_mul, neg_zero] },
    { rw norm_eq_zero at hy,
      rw [hy, inner_zero_right, zero_mul, neg_zero] } },
  { field_simp [h],
    ring }
end

/-- The angle between two vectors is zero if and only if they are
nonzero and one is a positive multiple of the other. -/
lemma angle_eq_zero_iff (x y : V) : angle x y = 0 ↔ (x ≠ 0 ∧ ∃ (r : ℝ), 0 < r ∧ y = r • x) :=
begin
  unfold angle,
  rw [←inner_div_norm_mul_norm_eq_one_iff, ←real.arccos_one],
  split,
  { intro h,
    exact real.arccos_inj (abs_le.mp (abs_inner_div_norm_mul_norm_le_one x y)).1
                          (abs_le.mp (abs_inner_div_norm_mul_norm_le_one x y)).2
                          (by norm_num)
                          (by norm_num)
                          h },
  { intro h,
    rw h }
end

/-- The angle between two vectors is π if and only if they are nonzero
and one is a negative multiple of the other. -/
lemma angle_eq_pi_iff (x y : V) : angle x y = π ↔ (x ≠ 0 ∧ ∃ (r : ℝ), r < 0 ∧ y = r • x) :=
begin
  unfold angle,
  rw [←inner_div_norm_mul_norm_eq_neg_one_iff, ←real.arccos_neg_one],
  split,
  { intro h,
    exact real.arccos_inj (abs_le.mp (abs_inner_div_norm_mul_norm_le_one x y)).1
                          (abs_le.mp (abs_inner_div_norm_mul_norm_le_one x y)).2
                          (by norm_num)
                          (by norm_num)
                          h },
  { intro h,
    rw h }
end

/-- If the angle between two vectors is π, the angles between those
vectors and a third vector add to π. -/
lemma angle_add_angle_eq_pi_of_angle_eq_pi {x y : V} (z : V) (h : angle x y = π) :
  angle x z + angle y z = π :=
begin
  rw angle_eq_pi_iff at h,
  rcases h with ⟨hx, ⟨r, ⟨hr, hxy⟩⟩⟩,
  rw [hxy, angle_smul_left_of_neg x z hr, angle_neg_left,
      add_sub_cancel'_right]
end

/-- Two vectors have inner product 0 if and only if the angle between
them is π/2. -/
lemma inner_eq_zero_iff_angle_eq_pi_div_two (x y : V) : inner x y = 0 ↔ angle x y = π / 2 :=
begin
  split,
  { intro h,
    unfold angle,
    rw [h, zero_div, real.arccos_zero] },
  { intro h,
    unfold angle at h,
    rw ←real.arccos_zero at h,
    have h2 : inner x y / (∥x∥ * ∥y∥) = 0 :=
      real.arccos_inj (abs_le.mp (abs_inner_div_norm_mul_norm_le_one x y)).1
                      (abs_le.mp (abs_inner_div_norm_mul_norm_le_one x y)).2
                      (by norm_num)
                      (by norm_num)
                      h,
    by_cases h : (∥x∥ * ∥y∥) = 0,
    { cases eq_zero_or_eq_zero_of_mul_eq_zero h with hx hy,
      { rw norm_eq_zero at hx,
        rw [hx, inner_zero_left] },
      { rw norm_eq_zero at hy,
        rw [hy, inner_zero_right] } },
    { simpa [h, div_eq_zero_iff] using h2 } },
end

/-- Pythagorean theorem, if-and-only-if vector angle form. -/
lemma norm_add_square_eq_norm_square_add_norm_square_iff_angle_eq_pi_div_two (x y : V) :
  ∥x + y∥ * ∥x + y∥ = ∥x∥ * ∥x∥ + ∥y∥ * ∥y∥ ↔ angle x y = π / 2 :=
begin
  rw norm_add_square_eq_norm_square_add_norm_square_iff_inner_eq_zero,
  exact inner_eq_zero_iff_angle_eq_pi_div_two x y
end

/-- Pythagorean theorem, vector angle form. -/
lemma norm_add_square_eq_norm_square_add_norm_square' (x y : V) (h : angle x y = π / 2) :
  ∥x + y∥ * ∥x + y∥ = ∥x∥ * ∥x∥ + ∥y∥ * ∥y∥ :=
(norm_add_square_eq_norm_square_add_norm_square_iff_angle_eq_pi_div_two x y).2 h

/-- Pythagorean theorem, subtracting vectors, if-and-only-if vector angle form. -/
lemma norm_sub_square_eq_norm_square_add_norm_square_iff_angle_eq_pi_div_two (x y : V) :
  ∥x - y∥ * ∥x - y∥ = ∥x∥ * ∥x∥ + ∥y∥ * ∥y∥ ↔ angle x y = π / 2 :=
begin
  rw norm_sub_square_eq_norm_square_add_norm_square_iff_inner_eq_zero,
  exact inner_eq_zero_iff_angle_eq_pi_div_two x y
end

/-- Pythagorean theorem, subtracting vectors, vector angle form. -/
lemma norm_sub_square_eq_norm_square_add_norm_square' (x y : V) (h : angle x y = π / 2) :
  ∥x - y∥ * ∥x - y∥ = ∥x∥ * ∥x∥ + ∥y∥ * ∥y∥ :=
(norm_sub_square_eq_norm_square_add_norm_square_iff_angle_eq_pi_div_two x y).2 h

/-- Law of cosines (cosine rule), vector angle form. -/
lemma norm_sub_square_eq_norm_square_add_norm_square_sub_two_mul_norm_mul_norm_mul_cos_angle
    (x y : V) :
  ∥x - y∥ * ∥x - y∥ = ∥x∥ * ∥x∥ + ∥y∥ * ∥y∥ - 2 * ∥x∥ * ∥y∥ * real.cos (angle x y) :=
by rw [(show 2 * ∥x∥ * ∥y∥ * real.cos (angle x y) =
             2 * (real.cos (angle x y) * (∥x∥ * ∥y∥)), by ring),
       cos_angle_mul_norm_mul_norm, ←inner_self_eq_norm_square,
       ←inner_self_eq_norm_square, ←inner_self_eq_norm_square, inner_sub_sub_self,
       sub_add_eq_add_sub]

/-- Pons asinorum, vector angle form. -/
lemma angle_sub_eq_angle_sub_rev_of_norm_eq {x y : V} (h : ∥x∥ = ∥y∥) :
  angle x (x - y) = angle y (y - x) :=
begin
  refine real.cos_inj_of_nonneg_of_le_pi (angle_nonneg _ _)
                                         (angle_le_pi _ _)
                                         (angle_nonneg _ _)
                                         (angle_le_pi _ _) _,
  rw [cos_angle, cos_angle, h, ←neg_sub, norm_neg, neg_sub,
      inner_sub_right, inner_sub_right, inner_self_eq_norm_square, inner_self_eq_norm_square, h,
      inner_comm x y]
end

/-- Converse of pons asinorum, vector angle form. -/
lemma norm_eq_of_angle_sub_eq_angle_sub_rev_of_angle_ne_pi {x y : V}
    (h : angle x (x - y) = angle y (y - x)) (hpi : angle x y ≠ π) : ∥x∥ = ∥y∥ :=
begin
  replace h := real.arccos_inj
    (abs_le.mp (abs_inner_div_norm_mul_norm_le_one x (x - y))).1
    (abs_le.mp (abs_inner_div_norm_mul_norm_le_one x (x - y))).2
    (abs_le.mp (abs_inner_div_norm_mul_norm_le_one y (y - x))).1
    (abs_le.mp (abs_inner_div_norm_mul_norm_le_one y (y - x))).2
    h,
  by_cases hxy : x = y,
  { rw hxy },
  { rw [←norm_neg (y - x), neg_sub, mul_comm, mul_comm ∥y∥, div_eq_mul_inv, div_eq_mul_inv,
        mul_inv_rev', mul_inv_rev', ←mul_assoc, ←mul_assoc] at h,
    replace h :=
      mul_right_cancel' (inv_ne_zero (λ hz, hxy (eq_of_sub_eq_zero (norm_eq_zero.1 hz)))) h,
    rw [inner_sub_right, inner_sub_right, inner_comm y x, inner_self_eq_norm_square,
        inner_self_eq_norm_square, mul_sub_right_distrib, mul_sub_right_distrib,
        mul_self_mul_inv, mul_self_mul_inv, sub_eq_sub_iff_sub_eq_sub,
        ←mul_sub_left_distrib] at h,
    by_cases hx0 : x = 0,
    { rw [hx0, norm_zero, inner_zero_left, zero_mul, zero_sub, neg_eq_zero] at h,
      rw [hx0, norm_zero, h] },
    { by_cases hy0 : y = 0,
      { rw [hy0, norm_zero, inner_zero_right, zero_mul, sub_zero] at h,
        rw [hy0, norm_zero, h] },
      { rw [inv_sub_inv (λ hz, hx0 (norm_eq_zero.1 hz)) (λ hz, hy0 (norm_eq_zero.1 hz)),
            ←neg_sub, ←mul_div_assoc, mul_comm, mul_div_assoc, ←mul_neg_one] at h,
        symmetry,
        by_contradiction hyx,
        replace h := (mul_left_cancel' (sub_ne_zero_of_ne hyx) h).symm,
        rw [inner_div_norm_mul_norm_eq_neg_one_iff, ←angle_eq_pi_iff] at h,
        exact hpi h } } }
end

/-- The cosine of the sum of two angles in a possibly degenerate
triangle (where two given sides are nonzero), vector angle form. -/
lemma cos_angle_sub_add_angle_sub_rev_eq_neg_cos_angle {x y : V} (hx : x ≠ 0) (hy : y ≠ 0) :
  real.cos (angle x (x - y) + angle y (y - x)) = -real.cos (angle x y) :=
begin
  by_cases hxy : x = y,
  { rw [hxy, angle_self hy],
    simp },
  { rw [real.cos_add, cos_angle, cos_angle, cos_angle],
    have hxn : ∥x∥ ≠ 0 := (λ h, hx (norm_eq_zero.1 h)),
    have hyn : ∥y∥ ≠ 0 := (λ h, hy (norm_eq_zero.1 h)),
    have hxyn : ∥x - y∥ ≠ 0 := (λ h, hxy (eq_of_sub_eq_zero (norm_eq_zero.1 h))),
    apply mul_right_cancel' hxn,
    apply mul_right_cancel' hyn,
    apply mul_right_cancel' hxyn,
    apply mul_right_cancel' hxyn,
    have H1 : real.sin (angle x (x - y)) * real.sin (angle y (y - x)) *
                ∥x∥ * ∥y∥ * ∥x - y∥ * ∥x - y∥ =
              (real.sin (angle x (x - y)) * (∥x∥ * ∥x - y∥)) *
                (real.sin (angle y (y - x)) * (∥y∥ * ∥x - y∥)), { ring },
    have H2 : inner x x * (inner x x - inner x y - (inner x y - inner y y)) -
                (inner x x - inner x y) * (inner x x - inner x y) =
              inner x x * inner y y - inner x y * inner x y, { ring },
    have H3 : inner y y * (inner y y - inner x y - (inner x y - inner x x)) -
                (inner y y - inner x y) * (inner y y - inner x y) =
              inner x x * inner y y - inner x y * inner x y, { ring },
    rw [mul_sub_right_distrib, mul_sub_right_distrib, mul_sub_right_distrib,
        mul_sub_right_distrib, H1, sin_angle_mul_norm_mul_norm, norm_sub_rev x y,
        sin_angle_mul_norm_mul_norm, norm_sub_rev y x, inner_sub_left, inner_sub_left,
        inner_sub_right, inner_sub_right, inner_sub_right, inner_sub_right, inner_comm y x, H2,
        H3, real.mul_self_sqrt (sub_nonneg_of_le (inner_mul_inner_self_le x y)),
        inner_self_eq_norm_square, inner_self_eq_norm_square,
        inner_eq_norm_mul_self_add_norm_mul_self_sub_norm_sub_mul_self_div_two],
    field_simp [hxn, hyn, hxyn],
    ring }
end

/-- The sine of the sum of two angles in a possibly degenerate
triangle (where two given sides are nonzero), vector angle form. -/
lemma sin_angle_sub_add_angle_sub_rev_eq_sin_angle {x y : V} (hx : x ≠ 0) (hy : y ≠ 0) :
  real.sin (angle x (x - y) + angle y (y - x)) = real.sin (angle x y) :=
begin
  by_cases hxy : x = y,
  { rw [hxy, angle_self hy],
    simp },
  { rw [real.sin_add, cos_angle, cos_angle],
    have hxn : ∥x∥ ≠ 0 := (λ h, hx (norm_eq_zero.1 h)),
    have hyn : ∥y∥ ≠ 0 := (λ h, hy (norm_eq_zero.1 h)),
    have hxyn : ∥x - y∥ ≠ 0 := (λ h, hxy (eq_of_sub_eq_zero (norm_eq_zero.1 h))),
    apply mul_right_cancel' hxn,
    apply mul_right_cancel' hyn,
    apply mul_right_cancel' hxyn,
    apply mul_right_cancel' hxyn,
    have H1 : real.sin (angle x (x - y)) * (inner y (y - x) / (∥y∥ * ∥y - x∥)) * ∥x∥ * ∥y∥ * ∥x - y∥ =
                real.sin (angle x (x - y)) * (∥x∥ * ∥x - y∥) *
                  (inner y (y - x) / (∥y∥ * ∥y - x∥)) * ∥y∥, { ring },
    have H2 : inner x (x - y) / (∥x∥ * ∥y - x∥) * real.sin (angle y (y - x)) * ∥x∥ * ∥y∥ * ∥y - x∥ =
                inner x (x - y) / (∥x∥ * ∥y - x∥) *
                  (real.sin (angle y (y - x)) * (∥y∥ * ∥y - x∥)) * ∥x∥, { ring },
    have H3 : inner x x * (inner x x - inner x y - (inner x y - inner y y)) -
                (inner x x - inner x y) * (inner x x - inner x y) =
              inner x x * inner y y - inner x y * inner x y, { ring },
    have H4 : inner y y * (inner y y - inner x y - (inner x y - inner x x)) -
                (inner y y - inner x y) * (inner y y - inner x y) =
              inner x x * inner y y - inner x y * inner x y, { ring },
    rw [right_distrib, right_distrib, right_distrib, right_distrib, H1,
        sin_angle_mul_norm_mul_norm, norm_sub_rev x y, H2, sin_angle_mul_norm_mul_norm,
        norm_sub_rev y x, mul_assoc (real.sin (angle x y)), sin_angle_mul_norm_mul_norm,
        inner_sub_left, inner_sub_left, inner_sub_right, inner_sub_right, inner_sub_right,
        inner_sub_right, inner_comm y x, H3, H4, inner_self_eq_norm_square,
        inner_self_eq_norm_square,
        inner_eq_norm_mul_self_add_norm_mul_self_sub_norm_sub_mul_self_div_two],
    field_simp [hxn, hyn, hxyn],
    ring }
end

/-- The cosine of the sum of the angles of a possibly degenerate
triangle (where two given sides are nonzero), vector angle form. -/
lemma cos_angle_add_angle_sub_add_angle_sub_eq_neg_one {x y : V} (hx : x ≠ 0) (hy : y ≠ 0) :
  real.cos (angle x y + angle x (x - y) + angle y (y - x)) = -1 :=
by rw [add_assoc, real.cos_add, cos_angle_sub_add_angle_sub_rev_eq_neg_cos_angle hx hy,
       sin_angle_sub_add_angle_sub_rev_eq_sin_angle hx hy, ←neg_mul_eq_mul_neg, ←neg_add',
       add_comm, ←pow_two, ←pow_two, real.sin_sq_add_cos_sq]

/-- The sine of the sum of the angles of a possibly degenerate
triangle (where two given sides are nonzero), vector angle form. -/
lemma sin_angle_add_angle_sub_add_angle_sub_eq_zero {x y : V} (hx : x ≠ 0) (hy : y ≠ 0) :
  real.sin (angle x y + angle x (x - y) + angle y (y - x)) = 0 :=
begin
  rw [add_assoc, real.sin_add, cos_angle_sub_add_angle_sub_rev_eq_neg_cos_angle hx hy,
      sin_angle_sub_add_angle_sub_rev_eq_sin_angle hx hy],
  ring
end

/-- The sum of the angles of a possibly degenerate triangle (where the
two given sides are nonzero), vector angle form. -/
lemma angle_add_angle_sub_add_angle_sub_eq_pi {x y : V} (hx : x ≠ 0) (hy : y ≠ 0) :
  angle x y + angle x (x - y) + angle y (y - x) = π :=
begin
  have hcos := cos_angle_add_angle_sub_add_angle_sub_eq_neg_one hx hy,
  have hsin := sin_angle_add_angle_sub_add_angle_sub_eq_zero hx hy,
  rw real.sin_eq_zero_iff at hsin,
  cases hsin with n hn,
  symmetry' at hn,
  have h0 : 0 ≤ angle x y + angle x (x - y) + angle y (y - x) :=
    add_nonneg (add_nonneg (angle_nonneg _ _) (angle_nonneg _ _)) (angle_nonneg _ _),
  have h3 : angle x y + angle x (x - y) + angle y (y - x) ≤ π + π + π :=
    add_le_add (add_le_add (angle_le_pi _ _) (angle_le_pi _ _)) (angle_le_pi _ _),
  have h3lt : angle x y + angle x (x - y) + angle y (y - x) < π + π + π,
  { by_contradiction hnlt,
    have hxy : angle x y = π,
    { by_contradiction hxy,
      exact hnlt (add_lt_add_of_lt_of_le (add_lt_add_of_lt_of_le
                                           (lt_of_le_of_ne (angle_le_pi _ _) hxy)
                                         (angle_le_pi _ _)) (angle_le_pi _ _)) },
    rw hxy at hnlt,
    rw angle_eq_pi_iff at hxy,
    rcases hxy with ⟨hx, ⟨r, ⟨hr, hxr⟩⟩⟩,
    rw [hxr, ←one_smul ℝ x, ←mul_smul, mul_one, ←sub_smul, one_smul, sub_eq_add_neg,
        angle_smul_right_of_pos _ _ (add_pos zero_lt_one (neg_pos_of_neg hr)), angle_self hx,
        add_zero] at hnlt,
    apply hnlt,
    rw add_assoc,
    exact add_lt_add_left (lt_of_le_of_lt (angle_le_pi _ _)
                                          (lt_add_of_pos_right π real.pi_pos)) _ },
  have hn0 : 0 ≤ n,
  { rw [hn, mul_nonneg_iff_right_nonneg_of_pos real.pi_pos] at h0,
    norm_cast at h0,
    exact h0 },
  have hn3 : n < 3,
  { rw [hn, (show π + π + π = 3 * π, by ring)] at h3lt,
    replace h3lt := lt_of_mul_lt_mul_right h3lt (le_of_lt real.pi_pos),
    norm_cast at h3lt,
    exact h3lt },
  interval_cases n,
  { rw hn at hcos,
    simp at hcos,
    norm_num at hcos },
  { rw hn,
    norm_num },
  { rw hn at hcos,
    simp at hcos,
    norm_num at hcos },
end

end inner_product_geometry

namespace euclidean_geometry
/-!
### Geometrical results on Euclidean affine spaces

This section develops some geometrical definitions and results on
Euclidean affine spaces.
-/
open inner_product_geometry

variables {V : Type*} {P : Type*} [inner_product_space V] [metric_space P]
    [normed_add_torsor V P]
include V

/-- The undirected angle at `p2` between the line segments to `p1` and
`p3`. If either of those points equals `p2`, this is π/2. Use
`open_locale euclidean_geometry` to access the `∠ p1 p2 p3`
notation. -/
def angle (p1 p2 p3 : P) : ℝ := angle (p1 -ᵥ p2 : V) (p3 -ᵥ p2)

localized "notation `∠` := euclidean_geometry.angle" in euclidean_geometry

/-- The angle at a point does not depend on the order of the other two
points. -/
lemma angle_comm (p1 p2 p3 : P) : ∠ p1 p2 p3 = ∠ p3 p2 p1 :=
angle_comm _ _

/-- The angle at a point is nonnegative. -/
lemma angle_nonneg (p1 p2 p3 : P) : 0 ≤ ∠ p1 p2 p3 :=
angle_nonneg _ _

/-- The angle at a point is at most π. -/
lemma angle_le_pi (p1 p2 p3 : P) : ∠ p1 p2 p3 ≤ π :=
angle_le_pi _ _

/-- The angle ∠AAB at a point. -/
lemma angle_eq_left (p1 p2 : P) : ∠ p1 p1 p2 = π / 2 :=
begin
  unfold angle,
  rw vsub_self,
  exact angle_zero_left _
end

/-- The angle ∠ABB at a point. -/
lemma angle_eq_right (p1 p2 : P) : ∠ p1 p2 p2 = π / 2 :=
by rw [angle_comm, angle_eq_left]

/-- The angle ∠ABA at a point. -/
lemma angle_eq_of_ne {p1 p2 : P} (h : p1 ≠ p2) : ∠ p1 p2 p1 = 0 :=
angle_self (λ he, h (vsub_eq_zero_iff_eq.1 he))

/-- If the angle ∠ABC at a point is π, the angle ∠BAC is 0. -/
lemma angle_eq_zero_of_angle_eq_pi_left {p1 p2 p3 : P} (h : ∠ p1 p2 p3 = π) :
  ∠ p2 p1 p3 = 0 :=
begin
  unfold angle at h,
  rw angle_eq_pi_iff at h,
  rcases h with ⟨hp1p2, ⟨r, ⟨hr, hpr⟩⟩⟩,
  unfold angle,
  rw angle_eq_zero_iff,
  rw [←neg_vsub_eq_vsub_rev, neg_ne_zero] at hp1p2,
  use [hp1p2, -r + 1, add_pos (neg_pos_of_neg hr) zero_lt_one],
  rw [add_smul, ←neg_vsub_eq_vsub_rev p1 p2, smul_neg],
  simp [←hpr]
end

/-- If the angle ∠ABC at a point is π, the angle ∠BCA is 0. -/
lemma angle_eq_zero_of_angle_eq_pi_right {p1 p2 p3 : P} (h : ∠ p1 p2 p3 = π) :
  ∠ p2 p3 p1 = 0 :=
begin
  rw angle_comm at h,
  exact angle_eq_zero_of_angle_eq_pi_left h
end

/-- If ∠BCD = π, then ∠ABC = ∠ABD. -/
lemma angle_eq_angle_of_angle_eq_pi (p1 : P) {p2 p3 p4 : P} (h : ∠ p2 p3 p4 = π) :
  ∠ p1 p2 p3 = ∠ p1 p2 p4 :=
begin
  unfold angle at h,
  rw angle_eq_pi_iff at h,
  rcases h with ⟨hp2p3, ⟨r, ⟨hr, hpr⟩⟩⟩,
  unfold angle,
  symmetry,
  convert angle_smul_right_of_pos _ _ (add_pos (neg_pos_of_neg hr) zero_lt_one),
  rw [add_smul, ←neg_vsub_eq_vsub_rev p2 p3, smul_neg],
  simp [←hpr]
end

/-- If ∠BCD = π, then ∠ACB + ∠ACD = π. -/
lemma angle_add_angle_eq_pi_of_angle_eq_pi (p1 : P) {p2 p3 p4 : P} (h : ∠ p2 p3 p4 = π) :
  ∠ p1 p3 p2 + ∠ p1 p3 p4 = π :=
begin
  unfold angle at h,
  rw [angle_comm p1 p3 p2, angle_comm p1 p3 p4],
  unfold angle,
  exact angle_add_angle_eq_pi_of_angle_eq_pi _ h
end

/-- Pythagorean theorem, if-and-only-if angle-at-point form. -/
lemma dist_square_eq_dist_square_add_dist_square_iff_angle_eq_pi_div_two (p1 p2 p3 : P) :
  dist p1 p3 * dist p1 p3 = dist p1 p2 * dist p1 p2 + dist p3 p2 * dist p3 p2 ↔
    ∠ p1 p2 p3 = π / 2 :=
by erw [metric_space.dist_comm p3 p2, dist_eq_norm_vsub V p1 p3, dist_eq_norm_vsub V p1 p2,
        dist_eq_norm_vsub V p2 p3,
        ←norm_sub_square_eq_norm_square_add_norm_square_iff_angle_eq_pi_div_two,
        vsub_sub_vsub_cancel_right p1, ←neg_vsub_eq_vsub_rev p2 p3, norm_neg]

/-- Law of cosines (cosine rule), angle-at-point form. -/
lemma dist_square_eq_dist_square_add_dist_square_sub_two_mul_dist_mul_dist_mul_cos_angle
    (p1 p2 p3 : P) :
  dist p1 p3 * dist p1 p3 =
    dist p1 p2 * dist p1 p2 + dist p3 p2 * dist p3 p2 -
      2 * dist p1 p2 * dist p3 p2 * real.cos (∠ p1 p2 p3) :=
begin
  rw [dist_eq_norm_vsub V p1 p3, dist_eq_norm_vsub V p1 p2, dist_eq_norm_vsub V p3 p2],
  unfold angle,
  convert norm_sub_square_eq_norm_square_add_norm_square_sub_two_mul_norm_mul_norm_mul_cos_angle
          (p1 -ᵥ p2 : V) (p3 -ᵥ p2 : V),
  { exact (vsub_sub_vsub_cancel_right p1 p3 p2).symm },
  { exact (vsub_sub_vsub_cancel_right p1 p3 p2).symm }
end

/-- Pons asinorum, angle-at-point form. -/
lemma angle_eq_angle_of_dist_eq {p1 p2 p3 : P} (h : dist p1 p2 = dist p1 p3) :
  ∠ p1 p2 p3 = ∠ p1 p3 p2 :=
begin
  rw [dist_eq_norm_vsub V p1 p2, dist_eq_norm_vsub V p1 p3] at h,
  unfold angle,
  convert angle_sub_eq_angle_sub_rev_of_norm_eq h,
  { exact (vsub_sub_vsub_cancel_left p3 p2 p1).symm },
  { exact (vsub_sub_vsub_cancel_left p2 p3 p1).symm }
end

/-- Converse of pons asinorum, angle-at-point form. -/
lemma dist_eq_of_angle_eq_angle_of_angle_ne_pi {p1 p2 p3 : P} (h : ∠ p1 p2 p3 = ∠ p1 p3 p2)
    (hpi : ∠ p2 p1 p3 ≠ π) : dist p1 p2 = dist p1 p3 :=
begin
  unfold angle at h hpi,
  rw [dist_eq_norm_vsub V p1 p2, dist_eq_norm_vsub V p1 p3],
  rw [←angle_neg_neg, neg_vsub_eq_vsub_rev, neg_vsub_eq_vsub_rev] at hpi,
  rw [←vsub_sub_vsub_cancel_left p3 p2 p1, ←vsub_sub_vsub_cancel_left p2 p3 p1] at h,
  exact norm_eq_of_angle_sub_eq_angle_sub_rev_of_angle_ne_pi h hpi
end

/-- The sum of the angles of a possibly degenerate triangle (where the
given vertex is distinct from the others), angle-at-point. -/
lemma angle_add_angle_add_angle_eq_pi {p1 p2 p3 : P} (h2 : p2 ≠ p1) (h3 : p3 ≠ p1) :
  ∠ p1 p2 p3 + ∠ p2 p3 p1 + ∠ p3 p1 p2 = π :=
begin
  rw [add_assoc, add_comm, add_comm (∠ p2 p3 p1), angle_comm p2 p3 p1],
  unfold angle,
  rw [←angle_neg_neg (p1 -ᵥ p3), ←angle_neg_neg (p1 -ᵥ p2), neg_vsub_eq_vsub_rev,
      neg_vsub_eq_vsub_rev, neg_vsub_eq_vsub_rev, neg_vsub_eq_vsub_rev,
      ←vsub_sub_vsub_cancel_right p3 p2 p1, ←vsub_sub_vsub_cancel_right p2 p3 p1],
  exact angle_add_angle_sub_add_angle_sub_eq_pi (λ he, h3 (vsub_eq_zero_iff_eq.1 he))
                                                (λ he, h2 (vsub_eq_zero_iff_eq.1 he))
end

/-- The inner product of two vectors given with `weighted_vsub`, in
terms of the pairwise distances. -/
lemma inner_weighted_vsub {ι₁ : Type*} {s₁ : finset ι₁} {w₁ : ι₁ → ℝ} (p₁ : ι₁ → P)
    (h₁ : ∑ i in s₁, w₁ i = 0) {ι₂ : Type*} {s₂ : finset ι₂} {w₂ : ι₂ → ℝ} (p₂ : ι₂ → P)
    (h₂ : ∑ i in s₂, w₂ i = 0) :
  inner (s₁.weighted_vsub p₁ w₁) (s₂.weighted_vsub p₂ w₂) =
    (-∑ i₁ in s₁, ∑ i₂ in s₂,
      w₁ i₁ * w₂ i₂ * (dist (p₁ i₁) (p₂ i₂) * dist (p₁ i₁) (p₂ i₂))) / 2 :=
begin
  rw [finset.weighted_vsub_apply, finset.weighted_vsub_apply,
      inner_sum_smul_sum_smul_of_sum_eq_zero _ h₁ _ h₂],
  simp_rw [vsub_sub_vsub_cancel_right],
  congr,
  ext i₁,
  congr,
  ext i₂,
  rw dist_eq_norm_vsub V (p₁ i₁) (p₂ i₂)
end

/-- The distance between two points given with `affine_combination`,
in terms of the pairwise distances between the points in that
combination. -/
lemma dist_affine_combination {ι : Type*} {s : finset ι} {w₁ w₂ : ι → ℝ} (p : ι → P)
    (h₁ : ∑ i in s, w₁ i = 1) (h₂ : ∑ i in s, w₂ i = 1) :
  dist (s.affine_combination p w₁) (s.affine_combination p w₂) *
    dist (s.affine_combination p w₁) (s.affine_combination p w₂) =
    (-∑ i₁ in s, ∑ i₂ in s,
      (w₁ - w₂) i₁ * (w₁ - w₂) i₂ * (dist (p i₁) (p i₂) * dist (p i₁) (p i₂))) / 2 :=
begin
  rw [dist_eq_norm_vsub V (s.affine_combination p w₁) (s.affine_combination p w₂),
      ←inner_self_eq_norm_square, finset.affine_combination_vsub],
  have h : ∑ i in s, (w₁ - w₂) i = 0,
  { simp_rw [pi.sub_apply, finset.sum_sub_distrib, h₁, h₂, sub_self] },
  exact inner_weighted_vsub p h p h
end

open affine_subspace

variables {V}

/-- The orthogonal projection of a point onto a nonempty affine
subspace, whose direction is complete, as an unbundled function.  This
definition is only intended for use in setting up the bundled version
`orthogonal_projection` and should not be used once that is
defined. -/
def orthogonal_projection_fn {s : affine_subspace ℝ P} (hn : (s : set P).nonempty)
    (hc : is_complete (s.direction : set V)) (p : P) : P :=
classical.some $ inter_eq_singleton_of_nonempty_of_is_compl
  hn
  (mk'_nonempty p s.direction.orthogonal)
  ((direction_mk' p s.direction.orthogonal).symm ▸ submodule.is_compl_orthogonal_of_is_complete hc)

/-- The intersection of the subspace and the orthogonal subspace
through the given point is the `orthogonal_projection_fn` of that
point onto the subspace.  This lemma is only intended for use in
setting up the bundled version and should not be used once that is
defined. -/
lemma inter_eq_singleton_orthogonal_projection_fn {s : affine_subspace ℝ P}
    (hn : (s : set P).nonempty) (hc : is_complete (s.direction : set V)) (p : P) :
  (s : set P) ∩ (mk' p s.direction.orthogonal) = {orthogonal_projection_fn hn hc p} :=
classical.some_spec $ inter_eq_singleton_of_nonempty_of_is_compl
  hn
  (mk'_nonempty p s.direction.orthogonal)
  ((direction_mk' p s.direction.orthogonal).symm ▸ submodule.is_compl_orthogonal_of_is_complete hc)

/-- The `orthogonal_projection_fn` lies in the given subspace.  This
lemma is only intended for use in setting up the bundled version and
should not be used once that is defined. -/
lemma orthogonal_projection_fn_mem {s : affine_subspace ℝ P} (hn : (s : set P).nonempty)
    (hc : is_complete (s.direction : set V)) (p : P) : orthogonal_projection_fn hn hc p ∈ s :=
begin
  rw [←mem_coe, ←set.singleton_subset_iff, ←inter_eq_singleton_orthogonal_projection_fn],
  exact set.inter_subset_left _ _
end

/-- The `orthogonal_projection_fn` lies in the orthogonal
subspace.  This lemma is only intended for use in setting up the
bundled version and should not be used once that is defined. -/
lemma orthogonal_projection_fn_mem_orthogonal {s : affine_subspace ℝ P}
    (hn : (s : set P).nonempty) (hc : is_complete (s.direction : set V)) (p : P) :
  orthogonal_projection_fn hn hc p ∈ mk' p s.direction.orthogonal :=
begin
  rw [←mem_coe, ←set.singleton_subset_iff, ←inter_eq_singleton_orthogonal_projection_fn],
  exact set.inter_subset_right _ _
end

/-- Subtracting `p` from its `orthogonal_projection_fn` produces a
result in the orthogonal direction.  This lemma is only intended for
use in setting up the bundled version and should not be used once that
is defined. -/
lemma orthogonal_projection_fn_vsub_mem_direction_orthogonal {s : affine_subspace ℝ P}
    (hn : (s : set P).nonempty) (hc : is_complete (s.direction : set V)) (p : P) :
  orthogonal_projection_fn hn hc p -ᵥ p ∈ s.direction.orthogonal :=
direction_mk' p s.direction.orthogonal ▸
  vsub_mem_direction (orthogonal_projection_fn_mem_orthogonal hn hc p) (self_mem_mk' _ _)

/-- The orthogonal projection of a point onto a nonempty affine
subspace, whose direction is complete. The corresponding linear map
(mapping a vector to the difference between the projections of two
points whose difference is that vector) is the `orthogonal_projection`
for real inner product spaces, onto the direction of the affine
subspace being projected onto. -/
def orthogonal_projection {s : affine_subspace ℝ P} (hn : (s : set P).nonempty)
    (hc : is_complete (s.direction : set V)) : affine_map ℝ P P :=
{ to_fun := orthogonal_projection_fn hn hc,
  linear := orthogonal_projection hc,
  map_vadd' := λ p v, begin
    have hs : (orthogonal_projection hc) v +ᵥ orthogonal_projection_fn hn hc p ∈ s :=
      vadd_mem_of_mem_direction (orthogonal_projection_mem hc _)
                                (orthogonal_projection_fn_mem hn hc p),
    have ho : (orthogonal_projection hc) v +ᵥ orthogonal_projection_fn hn hc p ∈
      mk' (v +ᵥ p) s.direction.orthogonal,
    { rw [←vsub_right_mem_direction_iff_mem (self_mem_mk' _ _) _, direction_mk',
          vsub_vadd_eq_vsub_sub, vadd_vsub_assoc, add_comm, add_sub_assoc],
      refine submodule.add_mem _ (orthogonal_projection_fn_vsub_mem_direction_orthogonal hn hc p) _,
      rw submodule.mem_orthogonal',
      intros w hw,
      rw [←neg_sub, inner_neg_left, orthogonal_projection_inner_eq_zero hc _ w hw, neg_zero] },
    have hm : (orthogonal_projection hc) v +ᵥ orthogonal_projection_fn hn hc p ∈
      ({orthogonal_projection_fn hn hc (v +ᵥ p)} : set P),
    { rw ←inter_eq_singleton_orthogonal_projection_fn hn hc (v +ᵥ p),
      exact set.mem_inter hs ho },
    rw set.mem_singleton_iff at hm,
    exact hm.symm
  end }

@[simp] lemma orthogonal_projection_fn_eq {s : affine_subspace ℝ P} (hn : (s : set P).nonempty)
  (hc : is_complete (s.direction : set V)) (p : P) :
  orthogonal_projection_fn hn hc p = orthogonal_projection hn hc p := rfl
  
/-- The intersection of the subspace and the orthogonal subspace
through the given point is the `orthogonal_projection` of that point
onto the subspace. -/
lemma inter_eq_singleton_orthogonal_projection {s : affine_subspace ℝ P}
    (hn : (s : set P).nonempty) (hc : is_complete (s.direction : set V)) (p : P) :
  (s : set P) ∩ (mk' p s.direction.orthogonal) = {orthogonal_projection hn hc p} :=
inter_eq_singleton_orthogonal_projection_fn hn hc p

/-- The `orthogonal_projection` lies in the given subspace. -/
lemma orthogonal_projection_mem {s : affine_subspace ℝ P} (hn : (s : set P).nonempty)
    (hc : is_complete (s.direction : set V)) (p : P) : orthogonal_projection hn hc p ∈ s :=
orthogonal_projection_fn_mem hn hc p

/-- The `orthogonal_projection` lies in the orthogonal subspace. -/
lemma orthogonal_projection_mem_orthogonal {s : affine_subspace ℝ P}
    (hn : (s : set P).nonempty) (hc : is_complete (s.direction : set V)) (p : P) :
  orthogonal_projection hn hc p ∈ mk' p s.direction.orthogonal :=
orthogonal_projection_fn_mem_orthogonal hn hc p

/-- Subtracting a point in the given subspace from the
`orthogonal_projection` produces a result in the direction of the
given subspace. -/
lemma orthogonal_projection_vsub_mem_direction {s : affine_subspace ℝ P}
    (hn : (s : set P).nonempty) (hc : is_complete (s.direction : set V)) {p1 : P} (p2 : P)
    (hp1 : p1 ∈ s) :
  orthogonal_projection hn hc p2 -ᵥ p1 ∈ s.direction :=
vsub_mem_direction (orthogonal_projection_mem hn hc p2) hp1

/-- Subtracting the `orthogonal_projection` from a point in the given
subspace produces a result in the direction of the given subspace. -/
lemma vsub_orthogonal_projection_mem_direction {s : affine_subspace ℝ P}
    (hn : (s : set P).nonempty) (hc : is_complete (s.direction : set V)) {p1 : P} (p2 : P)
    (hp1 : p1 ∈ s) :
  p1 -ᵥ orthogonal_projection hn hc p2 ∈ s.direction :=
vsub_mem_direction hp1 (orthogonal_projection_mem hn hc p2)

/-- A point equals its orthogonal projection if and only if it lies in
the subspace. -/
lemma orthogonal_projection_eq_self_iff {s : affine_subspace ℝ P}
    (hn : (s : set P).nonempty) (hc : is_complete (s.direction : set V)) {p : P} :
  orthogonal_projection hn hc p = p ↔ p ∈ s :=
begin
  split,
  { exact λ h, h ▸ orthogonal_projection_mem hn hc p },
  { intro h,
    have hp : p ∈ ((s : set P) ∩ mk' p s.direction.orthogonal) := ⟨h, self_mem_mk' p _⟩,
    rw [inter_eq_singleton_orthogonal_projection hn hc p, set.mem_singleton_iff] at hp,
    exact hp.symm }
end

/-- The distance to a point's orthogonal projection is 0 iff it lies in the subspace. -/
lemma dist_orthogonal_projection_eq_zero_iff {s : affine_subspace ℝ P}
  (hn : (s : set P).nonempty) (hc : is_complete (s.direction : set V)) {p : P} :
  dist p (orthogonal_projection hn hc p) = 0 ↔ p ∈ s :=
by rw [dist_comm, dist_eq_zero, orthogonal_projection_eq_self_iff]

/-- The distance between a point and its orthogonal projection is
nonzero if it does not lie in the subspace. -/
lemma dist_orthogonal_projection_ne_zero_of_not_mem {s : affine_subspace ℝ P}
    (hn : (s : set P).nonempty) (hc : is_complete (s.direction : set V)) {p : P} (hp : p ∉ s) :
  dist p (orthogonal_projection hn hc p) ≠ 0 :=
mt (dist_orthogonal_projection_eq_zero_iff hn hc).mp hp

/-- Subtracting `p` from its `orthogonal_projection` produces a result
in the orthogonal direction. -/
lemma orthogonal_projection_vsub_mem_direction_orthogonal {s : affine_subspace ℝ P}
    (hn : (s : set P).nonempty) (hc : is_complete (s.direction : set V)) (p : P) :
  orthogonal_projection hn hc p -ᵥ p ∈ s.direction.orthogonal :=
orthogonal_projection_fn_vsub_mem_direction_orthogonal hn hc p

/-- Subtracting the `orthogonal_projection` from `p` produces a result
in the orthogonal direction. -/
lemma vsub_orthogonal_projection_mem_direction_orthogonal {s : affine_subspace ℝ P}
    (hn : (s : set P).nonempty) (hc : is_complete (s.direction : set V)) (p : P) :
  p -ᵥ orthogonal_projection hn hc p ∈ s.direction.orthogonal :=
direction_mk' p s.direction.orthogonal ▸
  vsub_mem_direction (self_mem_mk' _ _) (orthogonal_projection_mem_orthogonal hn hc p)

/-- Adding a vector to a point in the given subspace, then taking the
orthogonal projection, produces the original point if the vector was
in the orthogonal direction. -/
lemma orthogonal_projection_vadd_eq_self {s : affine_subspace ℝ P}
    (hn : (s : set P).nonempty) (hc : is_complete (s.direction : set V)) {p : P} (hp : p ∈ s)
    {v : V} (hv : v ∈ s.direction.orthogonal) : orthogonal_projection hn hc (v +ᵥ p) = p :=
begin
  have h := vsub_orthogonal_projection_mem_direction_orthogonal hn hc (v +ᵥ p),
  rw [vadd_vsub_assoc, submodule.add_mem_iff_right _ hv] at h,
  refine (eq_of_vsub_eq_zero _).symm,
  refine submodule.disjoint_def.1 s.direction.orthogonal_disjoint _ _ h,
  exact vsub_mem_direction hp (orthogonal_projection_mem hn hc (v +ᵥ p))
end

/-- Adding a vector to a point in the given subspace, then taking the
orthogonal projection, produces the original point if the vector is a
multiple of the result of subtracting a point's orthogonal projection
from that point. -/
lemma orthogonal_projection_vadd_smul_vsub_orthogonal_projection {s : affine_subspace ℝ P}
    (hn : (s : set P).nonempty) (hc : is_complete (s.direction : set V)) {p1 : P} (p2 : P)
    (r : ℝ) (hp : p1 ∈ s) :
  orthogonal_projection hn hc (r • (p2 -ᵥ orthogonal_projection hn hc p2 : V) +ᵥ p1) = p1 :=
orthogonal_projection_vadd_eq_self hn hc hp
  (submodule.smul_mem _ _ (vsub_orthogonal_projection_mem_direction_orthogonal hn hc _))

/-- The square of the distance from a point in `s` to `p` equals the
sum of the squares of the distances of the two points to the
`orthogonal_projection`. -/
lemma dist_square_eq_dist_orthogonal_projection_square_add_dist_orthogonal_projection_square
    {s : affine_subspace ℝ P} (hn : (s : set P).nonempty)
    (hc : is_complete (s.direction : set V)) {p1 : P} (p2 : P) (hp1 : p1 ∈ s) :
  dist p1 p2 * dist p1 p2 =
    dist p1 (orthogonal_projection hn hc p2) * dist p1 (orthogonal_projection hn hc p2) +
    dist p2 (orthogonal_projection hn hc p2) * dist p2 (orthogonal_projection hn hc p2) :=
begin
  rw [metric_space.dist_comm p2 _, dist_eq_norm_vsub V p1 _, dist_eq_norm_vsub V p1 _,
    dist_eq_norm_vsub V _ p2, ← vsub_add_vsub_cancel p1 (orthogonal_projection hn hc p2) p2,
    norm_add_square_eq_norm_square_add_norm_square_iff_inner_eq_zero],
  exact submodule.inner_right_of_mem_orthogonal
    (vsub_orthogonal_projection_mem_direction hn hc p2 hp1)
    (orthogonal_projection_vsub_mem_direction_orthogonal hn hc p2)
end

/-- The square of the distance between two points constructed by
adding multiples of the same orthogonal vector to points in the same
subspace. -/
lemma dist_square_smul_orthogonal_vadd_smul_orthogonal_vadd {s : affine_subspace ℝ P}
    {p1 p2 : P} (hp1 : p1 ∈ s) (hp2 : p2 ∈ s) (r1 r2 : ℝ) {v : V}
    (hv : v ∈ s.direction.orthogonal) :
  dist (r1 • v +ᵥ p1) (r2 • v +ᵥ p2) * dist (r1 • v +ᵥ p1) (r2 • v +ᵥ p2) =
    dist p1 p2 * dist p1 p2 + (r1 - r2) * (r1 - r2) * (∥v∥ * ∥v∥) :=
calc dist (r1 • v +ᵥ p1) (r2 • v +ᵥ p2) * dist (r1 • v +ᵥ p1) (r2 • v +ᵥ p2)
    = ∥(p1 -ᵥ p2) + (r1 - r2) • v∥ * ∥(p1 -ᵥ p2) + (r1 - r2) • v∥
  : by { rw [dist_eq_norm_vsub V (r1 • v +ᵥ p1), vsub_vadd_eq_vsub_sub, vadd_vsub_assoc, sub_smul],
         abel }
... = ∥p1 -ᵥ p2∥ * ∥p1 -ᵥ p2∥ + ∥(r1 - r2) • v∥ * ∥(r1 - r2) • v∥
  : norm_add_square_eq_norm_square_add_norm_square
      (submodule.inner_right_of_mem_orthogonal (vsub_mem_direction hp1 hp2)
        (submodule.smul_mem _ _ hv))
... = ∥(p1 -ᵥ p2 : V)∥ * ∥(p1 -ᵥ p2 : V)∥ + abs (r1 - r2) * abs (r1 - r2) * ∥v∥ * ∥v∥
  : by { rw [norm_smul, real.norm_eq_abs], ring }
... = dist p1 p2 * dist p1 p2 + (r1 - r2) * (r1 - r2) * (∥v∥ * ∥v∥)
  : by { rw [dist_eq_norm_vsub V p1, abs_mul_abs_self, mul_assoc] }

/-- `p` is equidistant from two points in `s` if and only if its
`orthogonal_projection` is. -/
lemma dist_eq_iff_dist_orthogonal_projection_eq {s : affine_subspace ℝ P}
    (hn : (s : set P).nonempty) (hc : is_complete (s.direction : set V)) {p1 p2 : P} (p3 : P)
    (hp1 : p1 ∈ s) (hp2 : p2 ∈ s) :
  dist p1 p3 = dist p2 p3 ↔
    dist p1 (orthogonal_projection hn hc p3) = dist p2 (orthogonal_projection hn hc p3) :=
begin
  rw [←mul_self_inj_of_nonneg dist_nonneg dist_nonneg,
      ←mul_self_inj_of_nonneg dist_nonneg dist_nonneg,
      dist_square_eq_dist_orthogonal_projection_square_add_dist_orthogonal_projection_square
        hn hc p3 hp1,
      dist_square_eq_dist_orthogonal_projection_square_add_dist_orthogonal_projection_square
        hn hc p3 hp2],
  simp
end

/-- `p` is equidistant from a set of points in `s` if and only if its
`orthogonal_projection` is. -/
lemma dist_set_eq_iff_dist_orthogonal_projection_eq {s : affine_subspace ℝ P}
    (hn : (s : set P).nonempty) (hc : is_complete (s.direction : set V)) {ps : set P}
    (hps : ps ⊆ s) (p : P) :
  (set.pairwise_on ps (λ p1 p2, dist p1 p = dist p2 p) ↔
    (set.pairwise_on ps (λ p1 p2, dist p1 (orthogonal_projection hn hc p) =
      dist p2 (orthogonal_projection hn hc p)))) :=
⟨λ h p1 hp1 p2 hp2 hne,
  (dist_eq_iff_dist_orthogonal_projection_eq hn hc p (hps hp1) (hps hp2)).1 (h p1 hp1 p2 hp2 hne),
λ h p1 hp1 p2 hp2 hne,
  (dist_eq_iff_dist_orthogonal_projection_eq hn hc p (hps hp1) (hps hp2)).2 (h p1 hp1 p2 hp2 hne)⟩

/-- There exists `r` such that `p` has distance `r` from all the
points of a set of points in `s` if and only if there exists (possibly
different) `r` such that its `orthogonal_projection` has that distance
from all the points in that set. -/
lemma exists_dist_eq_iff_exists_dist_orthogonal_projection_eq {s : affine_subspace ℝ P}
    (hn : (s : set P).nonempty) (hc : is_complete (s.direction : set V)) {ps : set P}
    (hps : ps ⊆ s) (p : P) :
  (∃ r, ∀ p1 ∈ ps, dist p1 p = r) ↔
    ∃ r, ∀ p1 ∈ ps, dist p1 (orthogonal_projection hn hc p) = r :=
begin
  have h := dist_set_eq_iff_dist_orthogonal_projection_eq hn hc hps p,
  simp_rw set.pairwise_on_eq_iff_exists_eq at h,
  exact h
end

/-- The induction step for the existence and uniqueness of the
circumcenter.  Given a nonempty set of points in a nonempty affine
subspace whose direction is complete, such that there is a unique
(circumcenter, circumradius) pair for those points in that subspace,
and a point `p` not in that subspace, there is a unique (circumcenter,
circumradius) pair for the set with `p` added, in the span of the
subspace with `p` added. -/
lemma exists_unique_dist_eq_of_insert {s : affine_subspace ℝ P} (hn : (s : set P).nonempty)
    (hc : is_complete (s.direction : set V)) {ps : set P} (hnps : ps.nonempty) {p : P}
    (hps : ps ⊆ s) (hp : p ∉ s)
    (hu : ∃! cccr : (P × ℝ), cccr.fst ∈ s ∧ ∀ p1 ∈ ps, dist p1 cccr.fst = cccr.snd) :
  ∃! cccr₂ : (P × ℝ), cccr₂.fst ∈ affine_span ℝ (insert p (s : set P)) ∧
    ∀ p1 ∈ insert p ps, dist p1 cccr₂.fst = cccr₂.snd :=
begin
  rcases hu with ⟨⟨cc, cr⟩, ⟨hcc, hcr⟩, hcccru⟩,
  simp only [prod.fst, prod.snd] at hcc hcr hcccru,
  let x := dist cc (orthogonal_projection hn hc p),
  let y := dist p (orthogonal_projection hn hc p),
  have hy0 : y ≠ 0 := dist_orthogonal_projection_ne_zero_of_not_mem hn hc hp,
  let ycc₂ := (x * x + y * y - cr * cr) / (2 * y),
  let cc₂ := (ycc₂ / y) • (p -ᵥ orthogonal_projection hn hc p : V) +ᵥ cc,
  let cr₂ := real.sqrt (cr * cr + ycc₂ * ycc₂),
  use (cc₂, cr₂),
  simp only [prod.fst, prod.snd],
  have hpo :
    p = (1 : ℝ) • (p -ᵥ orthogonal_projection hn hc p : V) +ᵥ orthogonal_projection hn hc p,
  { simp },
  split,
  { split,
    { refine vadd_mem_of_mem_direction _ (mem_affine_span ℝ (set.mem_insert_of_mem _ hcc)),
      rw direction_affine_span,
      exact submodule.smul_mem _ _
        (vsub_mem_vector_span ℝ (set.mem_insert _ _)
                                (set.mem_insert_of_mem _ (orthogonal_projection_mem hn hc _))) },
    { intros p1 hp1,
      rw [←mul_self_inj_of_nonneg dist_nonneg (real.sqrt_nonneg _),
          real.mul_self_sqrt (add_nonneg (mul_self_nonneg _) (mul_self_nonneg _))],
      cases hp1,
      { rw hp1,
        rw [hpo,
            dist_square_smul_orthogonal_vadd_smul_orthogonal_vadd
              (orthogonal_projection_mem hn hc p) hcc _ _
              (vsub_orthogonal_projection_mem_direction_orthogonal hn hc p),
            ←dist_eq_norm_vsub V p, dist_comm _ cc],
        field_simp [hy0],
        ring },
      { rw [dist_square_eq_dist_orthogonal_projection_square_add_dist_orthogonal_projection_square
              hn hc _ (hps hp1),
            orthogonal_projection_vadd_smul_vsub_orthogonal_projection hn hc _ _ hcc, hcr p1 hp1,
            dist_eq_norm_vsub V cc₂ cc, vadd_vsub, norm_smul, ←dist_eq_norm_vsub V,
            real.norm_eq_abs, abs_div, abs_of_nonneg dist_nonneg, div_mul_cancel _ hy0,
            abs_mul_abs_self] } } },
  { rintros ⟨cc₃, cr₃⟩ ⟨hcc₃, hcr₃⟩,
    simp only [prod.fst, prod.snd] at hcc₃ hcr₃,
    rw mem_affine_span_insert_iff (orthogonal_projection_mem hn hc p) at hcc₃,
    rcases hcc₃ with ⟨t₃, cc₃', hcc₃', hcc₃⟩,
    have hcr₃' : ∃ r, ∀ p1 ∈ ps, dist p1 cc₃ = r :=
      ⟨cr₃, λ p1 hp1, hcr₃ p1 (set.mem_insert_of_mem _ hp1)⟩,
    rw [exists_dist_eq_iff_exists_dist_orthogonal_projection_eq hn hc hps cc₃, hcc₃,
        orthogonal_projection_vadd_smul_vsub_orthogonal_projection hn hc _ _ hcc₃'] at hcr₃',
    cases hcr₃' with cr₃' hcr₃',
    have hu := hcccru (cc₃', cr₃'),
    simp only [prod.fst, prod.snd] at hu,
    replace hu := hu ⟨hcc₃', hcr₃'⟩,
    rw prod.ext_iff at hu,
    simp only [prod.fst, prod.snd] at hu,
    cases hu with hucc hucr,
    substs hucc hucr,
    have hcr₃val : cr₃ = real.sqrt (cr₃' * cr₃' + (t₃ * y) * (t₃ * y)),
    { cases hnps with p0 hp0,
      rw [←hcr₃ p0 (set.mem_insert_of_mem _ hp0), hcc₃,
          ←mul_self_inj_of_nonneg dist_nonneg (real.sqrt_nonneg _),
          real.mul_self_sqrt (add_nonneg (mul_self_nonneg _) (mul_self_nonneg _)),
          dist_square_eq_dist_orthogonal_projection_square_add_dist_orthogonal_projection_square
            hn hc _ (hps hp0),
          orthogonal_projection_vadd_smul_vsub_orthogonal_projection hn hc _ _ hcc₃', hcr p0 hp0,
          dist_eq_norm_vsub V _ cc₃', vadd_vsub, norm_smul, ←dist_eq_norm_vsub V p,
          real.norm_eq_abs, ←mul_assoc, mul_comm _ (abs t₃), ←mul_assoc, abs_mul_abs_self],
      ring },
    replace hcr₃ := hcr₃ p (set.mem_insert _ _),
    rw [hpo, hcc₃, hcr₃val, ←mul_self_inj_of_nonneg dist_nonneg (real.sqrt_nonneg _),
        dist_square_smul_orthogonal_vadd_smul_orthogonal_vadd
          (orthogonal_projection_mem hn hc p) hcc₃' _ _
          (vsub_orthogonal_projection_mem_direction_orthogonal hn hc p),
        dist_comm, ←dist_eq_norm_vsub V p,
        real.mul_self_sqrt (add_nonneg (mul_self_nonneg _) (mul_self_nonneg _))] at hcr₃,
    change x * x + _ * (y * y) = _ at hcr₃,
    rw [(show x * x + (1 - t₃) * (1 - t₃) * (y * y) =
           x * x + y * y - 2 * y * (t₃ * y) + t₃ * y * (t₃ * y), by ring), add_left_inj] at hcr₃,
    have ht₃ : t₃ = ycc₂ / y,
    { field_simp [←hcr₃, hy0],
      ring },
    subst ht₃,
    change cc₃ = cc₂ at hcc₃,
    congr',
    rw hcr₃val,
    congr' 2,
    field_simp [hy0],
    ring }
end

/-- Given a finite nonempty affinely independent family of points,
there is a unique (circumcenter, circumradius) pair for those points
in the affine subspace they span. -/
lemma exists_unique_dist_eq_of_affine_independent {ι : Type*} [hne : nonempty ι] [fintype ι]
    {p : ι → P} (ha : affine_independent ℝ p) :
  ∃! cccr : (P × ℝ), cccr.fst ∈ affine_span ℝ (set.range p) ∧
    ∀ i, dist (p i) cccr.fst = cccr.snd :=
begin
  generalize' hn : fintype.card ι = n,
  unfreezingI { induction n with m hm generalizing ι },
  { exfalso,
    have h := fintype.card_pos_iff.2 hne,
    rw hn at h,
    exact lt_irrefl 0 h },
  { cases m,
    { rw fintype.card_eq_one_iff at hn,
      cases hn with i hi,
      haveI : unique ι := ⟨⟨i⟩, hi⟩,
      use (p i, 0),
      simp only [prod.fst, prod.snd, set.range_unique, affine_subspace.mem_affine_span_singleton],
      split,
      { simp_rw [hi (default ι)],
        use rfl,
        intro i1,
        rw hi i1,
        exact dist_self _ },
      { rintros ⟨cc, cr⟩,
        simp only [prod.fst, prod.snd],
        rintros ⟨rfl, hdist⟩,
        rw hi (default ι),
        congr',
        rw ←hdist (default ι),
        exact dist_self _ } },
    { have i := hne.some,
      let ι2 := {x // x ≠ i},
      have hc : fintype.card ι2 = m + 1,
      { rw fintype.card_of_subtype (finset.univ.filter (λ x, x ≠ i)),
        { rw finset.filter_not,
          simp_rw eq_comm,
          rw [finset.filter_eq, if_pos (finset.mem_univ _),
              finset.card_sdiff (finset.subset_univ _), finset.card_singleton, finset.card_univ,
              hn],
          simp },
        { simp } },
      haveI : nonempty ι2 := fintype.card_pos_iff.1 (hc.symm ▸ nat.zero_lt_succ _),
      have ha2 : affine_independent ℝ (λ i2 : ι2, p i2) :=
        affine_independent_subtype_of_affine_independent ha _,
      replace hm := hm ha2 hc,
      have hr : set.range p = insert (p i) (set.range (λ i2 : ι2, p i2)),
      { change _ = insert _ (set.range (λ i2 : {x | x ≠ i}, p i2)),
        rw [←set.image_eq_range, ←set.image_univ, ←set.image_insert_eq],
        congr,
        ext,
        simp [classical.em] },
      change ∃! (cccr : P × ℝ), (_ ∧ ∀ i2, (λ q, dist q cccr.fst = cccr.snd) (p i2)),
      conv { congr, funext, conv { congr, skip, rw ←set.forall_range_iff } },
      dsimp only,
      rw hr,
      change ∃! (cccr : P × ℝ), (_ ∧ ∀ (i2 : ι2), (λ q, dist q cccr.fst = cccr.snd) (p i2)) at hm,
      conv at hm { congr, funext, conv { congr, skip, rw ←set.forall_range_iff } },
      have hs : affine_span ℝ (insert (p i) (set.range (λ (i2 : ι2), p i2))) =
        affine_span ℝ (insert (p i) (affine_span ℝ (set.range (λ (i2 : ι2), p i2)) : set P)),
      { rw [set.insert_eq, set.insert_eq, span_union, span_union, affine_span_coe] },
      rw hs,
      refine exists_unique_dist_eq_of_insert
        ((affine_span_nonempty ℝ _).2 (set.range_nonempty _))
        (submodule.complete_of_finite_dimensional _)
        (set.range_nonempty _)
        (subset_span_points ℝ _)
        _
        hm,
      convert not_mem_affine_span_diff_of_affine_independent ha i set.univ,
      change set.range (λ i2 : {x | x ≠ i}, p i2) = _,
      rw ←set.image_eq_range,
      congr,
      ext,
      simp,
      refl } }
end

end euclidean_geometry

namespace affine

namespace simplex

open euclidean_geometry

variables {V : Type*} {P : Type*} [inner_product_space V] [metric_space P]
    [normed_add_torsor V P]
include V

/-- The pair (circumcenter, circumradius) of a simplex. -/
def circumcenter_circumradius {n : ℕ} (s : simplex ℝ P n) : (P × ℝ) :=
(exists_unique_dist_eq_of_affine_independent s.independent).some

/-- The property satisfied by the (circumcenter, circumradius) pair. -/
lemma circumcenter_circumradius_unique_dist_eq {n : ℕ} (s : simplex ℝ P n) :
  (s.circumcenter_circumradius.fst ∈ affine_span ℝ (set.range s.points) ∧
    ∀ i, dist (s.points i) s.circumcenter_circumradius.fst = s.circumcenter_circumradius.snd) ∧
  (∀ cccr : (P × ℝ), (cccr.fst ∈ affine_span ℝ (set.range s.points) ∧
    ∀ i, dist (s.points i) cccr.fst = cccr.snd) → cccr = s.circumcenter_circumradius) :=
(exists_unique_dist_eq_of_affine_independent s.independent).some_spec

/-- The circumcenter of a simplex. -/
def circumcenter {n : ℕ} (s : simplex ℝ P n) : P :=
s.circumcenter_circumradius.fst

/-- The circumradius of a simplex. -/
def circumradius {n : ℕ} (s : simplex ℝ P n) : ℝ :=
s.circumcenter_circumradius.snd

/-- The circumcenter lies in the affine span. -/
lemma circumcenter_mem_affine_span {n : ℕ} (s : simplex ℝ P n) :
  s.circumcenter ∈ affine_span ℝ (set.range s.points) :=
s.circumcenter_circumradius_unique_dist_eq.1.1

/-- All points have distance from the circumcenter equal to the
circumradius. -/
@[simp] lemma dist_circumcenter_eq_circumradius {n : ℕ} (s : simplex ℝ P n) :
  ∀ i, dist (s.points i) s.circumcenter = s.circumradius :=
s.circumcenter_circumradius_unique_dist_eq.1.2

/-- All points have distance to the circumcenter equal to the
circumradius. -/
@[simp] lemma dist_circumcenter_eq_circumradius' {n : ℕ} (s : simplex ℝ P n) :
  ∀ i, dist s.circumcenter (s.points i) = s.circumradius :=
begin
  intro i,
  rw dist_comm,
  exact dist_circumcenter_eq_circumradius _ _
end

/-- Given a point in the affine span from which all the points are
equidistant, that point is the circumcenter. -/
lemma eq_circumcenter_of_dist_eq {n : ℕ} (s : simplex ℝ P n) {p : P}
    (hp : p ∈ affine_span ℝ (set.range s.points)) {r : ℝ} (hr : ∀ i, dist (s.points i) p = r) :
  p = s.circumcenter :=
begin
  have h := s.circumcenter_circumradius_unique_dist_eq.2 (p, r),
  simp only [hp, hr, forall_const, eq_self_iff_true, and_self, prod.ext_iff] at h,
  exact h.1
end

/-- Given a point in the affine span from which all the points are
equidistant, that distance is the circumradius. -/
lemma eq_circumradius_of_dist_eq {n : ℕ} (s : simplex ℝ P n) {p : P}
    (hp : p ∈ affine_span ℝ (set.range s.points)) {r : ℝ} (hr : ∀ i, dist (s.points i) p = r) :
  r = s.circumradius :=
begin
  have h := s.circumcenter_circumradius_unique_dist_eq.2 (p, r),
  simp only [hp, hr, forall_const, eq_self_iff_true, and_self, prod.ext_iff] at h,
  exact h.2
end

end simplex

end affine
