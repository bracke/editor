with Ada.Containers.Vectors;

package Editor.Folding is

   --  A line-based fold interval expressed in logical document rows.
   --  Start_Row remains visible when Collapsed is True; rows after the
   --  start through End_Row are hidden from viewport/render mapping only.
   type Fold_Range is record
      Start_Row : Natural;
      End_Row   : Natural;
      Collapsed : Boolean := False;
   end record;

   --  Fold range storage.  Phase 42 keeps the representation intentionally
   --  simple because folding is independent of the text buffer and no parser
   --  or persistence layer owns ranges yet.
   package Fold_Range_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Fold_Range);

   --  Complete folding state for an editor document.
   type Folding_State is record
      Ranges : Fold_Range_Vectors.Vector;
   end record;

   --  Remove all known fold ranges.
   --  @param State folding state to clear
   procedure Clear (State : in out Folding_State);

   --  Add a fold range if it spans at least two logical rows.
   --  Existing ranges with the same start row are extended rather than
   --  duplicated, preserving their collapsed/expanded state.
   --  @param State folding state to mutate
   --  @param Start_Row visible start row of the fold
   --  @param End_Row inclusive final row covered by the fold
   procedure Add_Fold
     (State     : in out Folding_State;
      Start_Row : Natural;
      End_Row   : Natural);

   --  Toggle the collapsed state of a fold whose Start_Row equals Row.
   --  Rows without a fold start are ignored.
   --  @param State folding state to mutate
   --  @param Row logical document row to toggle
   procedure Toggle_Fold_At_Row
     (State : in out Folding_State;
      Row   : Natural);

   --  Return True when Row is the start row of a known fold range.
   --  @param State folding state to inspect
   --  @param Row logical document row to test
   --  @return True if Row starts a fold range
   function Has_Fold_Start
     (State : Folding_State;
      Row   : Natural) return Boolean;

   --  Return the collapsed state for the fold starting at Row.
   --  @param State folding state to inspect
   --  @param Row logical document row to test
   --  @return True only when Row starts a collapsed fold
   function Is_Fold_Collapsed
     (State : Folding_State;
      Row   : Natural) return Boolean;

   --  Find the visible fold start that owns a hidden row.
   --  @param State folding state to inspect
   --  @param Row logical document row to resolve
   --  @param Found set True when Row is hidden by a collapsed fold
   --  @return owning fold start row when Found is True; otherwise Row
   function Fold_Start_For_Hidden_Row
     (State : Folding_State;
      Row   : Natural;
      Found : out Boolean) return Natural;

   --  Return True when Row is inside the collapsed interior of a fold.
   --  @param State folding state to inspect
   --  @param Row logical document row to test
   --  @return True if Row is hidden from viewport/render mapping
   function Is_Row_Hidden
     (State : Folding_State;
      Row   : Natural) return Boolean;

   --  Expand collapsed folds that hide Row.
   --  Only folds whose collapsed interior contains Row are expanded; unrelated
   --  folds are preserved.
   --  @param State folding state to mutate
   --  @param Row logical document row that must become visible
   procedure Expand_To_Reveal_Row
     (State : in out Folding_State;
      Row   : Natural);


   --  Convert a visible-row ordinal to the corresponding logical document row.
   --  @param State folding state to inspect
   --  @param Visible_Row zero-based visible-row ordinal
   --  @return logical document row represented by Visible_Row
   function Visible_Row_To_Document_Row
     (State       : Folding_State;
      Visible_Row : Natural) return Natural;

   --  Convert a visible logical document row to its visible-row ordinal.
   --  @param State folding state to inspect
   --  @param Row logical document row to resolve
   --  @param Found set True when Row is visible
   --  @return visible-row ordinal when Found is True; otherwise 0
   function Document_Row_To_Visible_Row
     (State : Folding_State;
      Row   : Natural;
      Found : out Boolean) return Natural;

   --  Count visible logical rows after applying collapsed folds.
   --  @param State folding state to inspect
   --  @param Document_Rows total logical document row count
   --  @return number of rows visible to line-based viewport mapping
   function Visible_Row_Count
     (State         : Folding_State;
      Document_Rows : Natural) return Natural;

end Editor.Folding;
