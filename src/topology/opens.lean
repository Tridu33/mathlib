/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Mario Carneiro, Floris van Doorn
-/
import topology.bases
import topology.homeomorph
/-!
# Open sets

## Summary

We define the subtype of open sets in a topological space.

## Main Definitions

- `opens α` is the type of open subsets of a topological space `α`.
- `open_nhds_of x` is the type of open subsets of a topological space `α` containing `x : α`.
-
-/

open filter set
variables {α : Type*} {β : Type*} {γ : Type*}
  [topological_space α] [topological_space β] [topological_space γ]

namespace topological_space
variable (α)
/-- The type of open subsets of a topological space. -/
def opens := {s : set α // is_open s}

variable {α}
namespace opens
instance : has_coe (opens α) (set α) := { coe := subtype.val }

lemma val_eq_coe (U : opens α) : U.1 = ↑U := rfl

/-- the coercion `opens α → set α` applied to a pair is the same as taking the first component -/
lemma coe_mk {α : Type*} [topological_space α] {U : set α} {hU : is_open U} :
  ↑(⟨U, hU⟩ : opens α) = U := rfl

instance : has_subset (opens α) :=
{ subset := λ U V, (U : set α) ⊆ V }

instance : has_mem α (opens α) :=
{ mem := λ a U, a ∈ (U : set α) }

@[simp] lemma subset_coe {U V : opens α} : ((U : set α) ⊆ (V : set α)) = (U ⊆ V) := rfl

@[simp] lemma mem_coe {x : α} {U : opens α} : (x ∈ (U : set α)) = (x ∈ U) := rfl

@[ext] lemma ext {U V : opens α} (h : (U : set α) = V) : U = V := subtype.ext_iff.mpr h

@[ext] lemma ext_iff {U V : opens α} : (U : set α) = V ↔ U = V :=
⟨opens.ext, congr_arg coe⟩

instance : partial_order (opens α) := subtype.partial_order _

/-- The interior of a set, as an element of `opens`. -/
def interior (s : set α) : opens α := ⟨interior s, is_open_interior⟩

lemma gc : galois_connection (coe : opens α → set α) interior :=
λ U s, ⟨λ h, interior_maximal h U.property, λ h, le_trans h interior_subset⟩

/-- The galois insertion between sets and opens, but ordered by reverse inclusion. -/
def gi : @galois_insertion (order_dual (set α)) (order_dual (opens α)) _ _ interior subtype.val :=
{ choice := λ s hs, ⟨s, interior_eq_iff_open.mp $ le_antisymm interior_subset hs⟩,
  gc := gc.dual,
  le_l_u := λ _, interior_subset,
  choice_eq := λ s hs, le_antisymm interior_subset hs }

@[simp] lemma gi_choice_val {s : order_dual (set α)} {hs} : (gi.choice s hs).val = s := rfl

instance : complete_lattice (opens α) :=
complete_lattice.copy
  (@order_dual.complete_lattice _ (galois_insertion.lift_complete_lattice (@gi α _)))
/- le  -/ (λ U V, U ⊆ V) rfl
/- top -/ ⟨set.univ, is_open_univ⟩ (subtype.ext_iff_val.mpr interior_univ.symm)
/- bot -/ ⟨∅, is_open_empty⟩ rfl
/- sup -/ (λ U V, ⟨↑U ∪ ↑V, is_open_union U.2 V.2⟩) rfl
/- inf -/ (λ U V, ⟨↑U ∩ ↑V, is_open_inter U.2 V.2⟩)
begin
  funext,
  apply subtype.ext_iff_val.mpr,
  exact (is_open_inter U.2 V.2).interior_eq.symm,
end
/- Sup -/ (λ Us, ⟨⋃₀ (coe '' Us), is_open_sUnion $ λ U hU,
by { rcases hU with ⟨⟨V, hV⟩, h, h'⟩, dsimp at h', subst h', exact hV}⟩)
begin
  funext,
  apply subtype.ext_iff_val.mpr,
  simp [Sup_range],
  refl,
end
/- Inf -/ _ rfl

instance : has_inter (opens α) := ⟨λ U V, U ⊓ V⟩
instance : has_union (opens α) := ⟨λ U V, U ⊔ V⟩
instance : has_emptyc (opens α) := ⟨⊥⟩
instance : inhabited (opens α) := ⟨∅⟩

@[simp] lemma inter_eq (U V : opens α) : U ∩ V = U ⊓ V := rfl
@[simp] lemma union_eq (U V : opens α) : U ∪ V = U ⊔ V := rfl
@[simp] lemma empty_eq : (∅ : opens α) = ⊥ := rfl

@[simp] lemma Sup_s {Us : set (opens α)} : ↑(Sup Us) = ⋃₀ ((coe : _ → set α) '' Us) :=
begin
  rw [@galois_connection.l_Sup (opens α) (set α) _ _ (coe : opens α → set α) interior gc Us],
  rw [set.sUnion_image]
end

lemma supr_def {ι} (s : ι → opens α) : (⨆ i, s i) = ⟨⋃ i, s i, is_open_Union $ λ i, (s i).2⟩ :=
by { ext, simp only [supr, opens.Sup_s, sUnion_image, bUnion_range], refl }

@[simp] lemma supr_s {ι} (s : ι → opens α) : ((⨆ i, s i : opens α) : set α) = ⋃ i, s i :=
by simp [supr_def]

theorem mem_supr {ι} {x : α} {s : ι → opens α} : x ∈ supr s ↔ ∃ i, x ∈ s i :=
by { rw [←mem_coe], simp, }

lemma open_embedding_of_le {U V : opens α} (i : U ≤ V) :
  open_embedding (set.inclusion i) :=
{ inj := set.inclusion_injective i,
  induced := (@induced_compose _ _ _ _ (set.inclusion i) coe).symm,
  open_range :=
  begin
    rw set.range_inclusion i,
    exact continuous_subtype_val U.val U.property
  end, }

def is_basis (B : set (opens α)) : Prop := is_topological_basis ((coe : _ → set α) '' B)

lemma is_basis_iff_nbhd {B : set (opens α)} :
  is_basis B ↔ ∀ {U : opens α} {x}, x ∈ U → ∃ U' ∈ B, x ∈ U' ∧ U' ⊆ U :=
begin
  split; intro h,
  { rintros ⟨sU, hU⟩ x hx,
    rcases (mem_nhds_of_is_topological_basis h).mp (mem_nhds_sets hU hx) with ⟨sV, ⟨⟨V, H₁, H₂⟩, hsV⟩⟩,
    refine ⟨V, H₁, _⟩,
    cases V, dsimp at H₂, subst H₂, exact hsV },
  { refine is_topological_basis_of_open_of_nhds _ _,
    { rintros sU ⟨U, ⟨H₁, H₂⟩⟩, subst H₂, exact U.property },
    { intros x sU hx hsU,
      rcases @h (⟨sU, hsU⟩ : opens α) x hx with ⟨V, hV, H⟩,
      exact ⟨V, ⟨V, hV, rfl⟩, H⟩ } }
end

lemma is_basis_iff_cover {B : set (opens α)} :
  is_basis B ↔ ∀ U : opens α, ∃ Us ⊆ B, U = Sup Us :=
begin
  split,
  { intros hB U,
    rcases sUnion_basis_of_is_open hB U.prop with ⟨sUs, H, hU⟩,
    existsi {U : opens α | U ∈ B ∧ ↑U ∈ sUs},
    split,
    { intros U hU, exact hU.left },
    { apply ext,
      rw [Sup_s, hU],
      congr,
      ext s; split; intro hs,
      { rcases H hs with ⟨V, hV⟩,
        rw ← hV.right at hs,
        refine ⟨V, ⟨⟨hV.left, hs⟩, hV.right⟩⟩ },
      { rcases hs with ⟨V, ⟨⟨H₁, H₂⟩, H₃⟩⟩,
        subst H₃, exact H₂ } } },
  { intro h,
    rw is_basis_iff_nbhd,
    intros U x hx,
    rcases h U with ⟨Us, hUs, H⟩,
    replace H := congr_arg (coe : _ → set α) H,
    rw Sup_s at H,
    change x ∈ ↑U at hx,
    rw H at hx,
    rcases set.mem_sUnion.mp hx with ⟨sV, ⟨⟨V, H₁, H₂⟩, hsV⟩⟩,
    refine ⟨V,hUs H₁,_⟩,
    cases V with V hV,
    dsimp at H₂, subst H₂,
    refine ⟨hsV,_⟩,
    change V ⊆ U, rw H,
    exact set.subset_sUnion_of_mem ⟨⟨V, _⟩, ⟨H₁, rfl⟩⟩ }
end

/-- The preimage of an open set, as an open set. -/
def comap {f : α → β} (hf : continuous f) (V : opens β) : opens α :=
⟨f ⁻¹' V.1, hf V.1 V.2⟩

@[simp] lemma comap_id (U : opens α) : U.comap continuous_id = U := by { ext, refl }

lemma comap_mono {f : α → β} (hf : continuous f) {V W : opens β} (hVW : V ⊆ W) :
  V.comap hf ⊆ W.comap hf :=
λ _ h, hVW h

@[simp] lemma coe_comap {f : α → β} (hf : continuous f) (U : opens β) :
  ↑(U.comap hf) = f ⁻¹' U := rfl

@[simp] lemma comap_val {f : α → β} (hf : continuous f) (U : opens β) :
  (U.comap hf).1 = f ⁻¹' U := rfl

protected lemma comap_comp {g : β → γ} {f : α → β} (hg : continuous g) (hf : continuous f)
  (U : opens γ) : U.comap (hg.comp hf) = (U.comap hg).comap hf :=
by { ext1, simp only [coe_comap, preimage_preimage] }

/-- A homeomorphism induces an equivalence on open sets, by taking comaps. -/
@[simp] protected def equiv (f : α ≃ₜ β) : opens α ≃ opens β :=
{ to_fun := opens.comap f.symm.continuous,
  inv_fun := opens.comap f.continuous,
  left_inv := by { intro U, ext1,
    simp only [coe_comap, ← preimage_comp, f.symm_comp_self, preimage_id] },
  right_inv := by { intro U, ext1,
    simp only [coe_comap, ← preimage_comp, f.self_comp_symm, preimage_id] } }

end opens

/-- The open neighborhoods of a point. See also `opens` or `nhds`. -/
def open_nhds_of (x : α) : Type* := { s : set α // is_open s ∧ x ∈ s }

instance open_nhds_of.inhabited {α : Type*} [topological_space α] (x : α) :
  inhabited (open_nhds_of x) := ⟨⟨set.univ, is_open_univ, set.mem_univ _⟩⟩

end topological_space
