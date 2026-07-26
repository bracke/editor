with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Buffer_Switcher.Filters is

   use type Switcher_Metadata_Filter_Kind;
   use type Switcher_Sort_Mode;

   function Trimmed (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

   procedure Clear_Metadata_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      State.Active_Filter := (Kind => No_Filter, Text => Null_Unbounded_String);
   end Clear_Metadata_Filter;

   procedure Set_Pinned_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      State.Active_Filter := (Kind => Pinned_Filter, Text => Null_Unbounded_String);
   end Set_Pinned_Filter;

   procedure Set_Group_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Name  : String)
   is
      Group : constant String := Trimmed (Name);
   begin
      State.Active_Filter := (Kind => Group_Filter, Text => To_Unbounded_String (Group));
   end Set_Group_Filter;

   procedure Set_Label_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Label : String)
   is
      Text : constant String := Trimmed (Label);
   begin
      State.Active_Filter := (Kind => Label_Filter, Text => To_Unbounded_String (Text));
   end Set_Label_Filter;

   procedure Set_Noted_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      State.Active_Filter := (Kind => Noted_Filter, Text => Null_Unbounded_String);
   end Set_Noted_Filter;

   procedure Set_Dirty_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      State.Active_Filter := (Kind => Dirty_Filter, Text => Null_Unbounded_String);
   end Set_Dirty_Filter;

   procedure Set_Clean_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      State.Active_Filter := (Kind => Clean_Filter, Text => Null_Unbounded_String);
   end Set_Clean_Filter;

   procedure Set_Missing_Or_Conflict_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      State.Active_Filter :=
        (Kind => Missing_Or_Conflict_Filter, Text => Null_Unbounded_String);
   end Set_Missing_Or_Conflict_Filter;

   procedure Set_Project_Owned_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      State.Active_Filter := (Kind => Project_Owned_Filter, Text => Null_Unbounded_String);
   end Set_Project_Owned_Filter;

   procedure Set_Outside_Project_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      State.Active_Filter := (Kind => Outside_Project_Filter, Text => Null_Unbounded_String);
   end Set_Outside_Project_Filter;

   procedure Set_Scratch_Filter
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      State.Active_Filter := (Kind => Scratch_Filter, Text => Null_Unbounded_String);
   end Set_Scratch_Filter;

   function Has_Metadata_Filter
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return Boolean is
   begin
      return State.Active_Filter.Kind /= No_Filter;
   end Has_Metadata_Filter;

   function Metadata_Filter
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State)
      return Switcher_Metadata_Filter is
   begin
      return State.Active_Filter;
   end Metadata_Filter;

   function Metadata_Filter_Description
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return String is
   begin
      case State.Active_Filter.Kind is
         when No_Filter =>
            return "";
         when Pinned_Filter =>
            return "pinned";
         when Group_Filter =>
            return "group " & To_String (State.Active_Filter.Text);
         when Label_Filter =>
            return "label " & To_String (State.Active_Filter.Text);
         when Noted_Filter =>
            return "noted";
         when Dirty_Filter =>
            return "dirty buffers";
         when Clean_Filter =>
            return "clean buffers";
         when Missing_Or_Conflict_Filter =>
            return "missing or conflicted buffers";
         when Project_Owned_Filter =>
            return "project buffers";
         when Outside_Project_Filter =>
            return "outside project buffers";
         when Scratch_Filter =>
            return "scratch buffers";
      end case;
   end Metadata_Filter_Description;

   procedure Set_Sort_Mode
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Mode  : Switcher_Sort_Mode) is
   begin
      State.Active_Sort := Mode;
   end Set_Sort_Mode;

   procedure Clear_Sort_Mode
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      State.Active_Sort := Default_Sort;
   end Clear_Sort_Mode;

   procedure Next_Sort_Mode
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      if State.Active_Sort = Switcher_Sort_Mode'Last then
         State.Active_Sort := Switcher_Sort_Mode'First;
      else
         State.Active_Sort := Switcher_Sort_Mode'Succ (State.Active_Sort);
      end if;
   end Next_Sort_Mode;

   procedure Previous_Sort_Mode
     (State : in out Editor.Buffer_Switcher.Buffer_Switcher_State) is
   begin
      if State.Active_Sort = Switcher_Sort_Mode'First then
         State.Active_Sort := Switcher_Sort_Mode'Last;
      else
         State.Active_Sort := Switcher_Sort_Mode'Pred (State.Active_Sort);
      end if;
   end Previous_Sort_Mode;

   function Sort_Mode
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State)
      return Switcher_Sort_Mode is
   begin
      return State.Active_Sort;
   end Sort_Mode;

   function Sort_Mode_Description
     (State : Editor.Buffer_Switcher.Buffer_Switcher_State) return String is
   begin
      case State.Active_Sort is
         when Default_Sort =>
            return "default";
         when Recent_Sort =>
            return "recent";
         when Name_Sort =>
            return "name";
         when Pinned_Sort =>
            return "pinned first";
         when Group_Sort =>
            return "group";
         when Label_Sort =>
            return "label";
      end case;
   end Sort_Mode_Description;

end Editor.Buffer_Switcher.Filters;
