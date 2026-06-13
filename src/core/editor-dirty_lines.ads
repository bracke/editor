with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Dirty_Lines is

   type Dirty_Line_Kind is
     (Clean_Line,
      Added_Line,
      Modified_Line);

   type Dirty_Line_State is private;

   procedure Clear
     (State : in out Dirty_Line_State);

   procedure Set_Baseline_Text
     (State : in out Dirty_Line_State;
      Text  : String);

   function Has_Baseline
     (State : Dirty_Line_State) return Boolean;

   function Baseline_Line_Count
     (State : Dirty_Line_State) return Natural;

   function Dirty_Line_Count
     (State : Dirty_Line_State) return Natural;

   function Kind_For_Row
     (State : Dirty_Line_State;
      Row   : Natural) return Dirty_Line_Kind;

   function Is_Dirty_Row
     (State : Dirty_Line_State;
      Row   : Natural) return Boolean;

   procedure Recompute
     (State        : in out Dirty_Line_State;
      Current_Text : String);

   procedure Clear_Dirty_State_To_Current
     (State        : in out Dirty_Line_State;
      Current_Text : String);

private

   package Line_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String,
      "="          => Ada.Strings.Unbounded."=");

   package Kind_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Dirty_Line_Kind);

   type Dirty_Line_State is record
      Has_Saved_Baseline : Boolean := False;
      Baseline_Lines     : Line_Vectors.Vector;
      Kinds              : Kind_Vectors.Vector;
      Dirty_Count        : Natural := 0;
   end record;

end Editor.Dirty_Lines;
