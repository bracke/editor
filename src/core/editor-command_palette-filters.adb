with Editor.Commands.Classification;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands.Descriptors;
with Editor.Keybindings;
with Editor.Text_Helpers;

package body Editor.Command_Palette.Filters is

   Availability_Filter_State : Command_Palette_Availability_Filter :=
     Palette_All_Commands;
   Category_Filter_Active : Boolean := False;
   Category_Filter_Label_State : Unbounded_String := Null_Unbounded_String;
   Destructive_Filter_State : Boolean := False;
   Keybinding_Filter_State : Command_Palette_Keybinding_Filter :=
     Palette_All_Keybinding_States;

   function Lower (S : String) return String
     renames Editor.Text_Helpers.Lower;

   procedure Clear_Transient_Filters is
   begin
      Availability_Filter_State := Palette_All_Commands;
      Category_Filter_Active := False;
      Category_Filter_Label_State := Null_Unbounded_String;
      Destructive_Filter_State := False;
      Keybinding_Filter_State := Palette_All_Keybinding_States;
   end Clear_Transient_Filters;

   function Transient_Filters_Clear return Boolean is
   begin
      return Availability_Filter_State = Palette_All_Commands
        and then not Category_Filter_Active
        and then Length (Category_Filter_Label_State) = 0
        and then not Destructive_Filter_State
        and then Keybinding_Filter_State = Palette_All_Keybinding_States;
   end Transient_Filters_Clear;

   procedure Set_Availability_Filter
     (Filter : Command_Palette_Availability_Filter) is
   begin
      Availability_Filter_State := Filter;
   end Set_Availability_Filter;

   function Current_Availability_Filter
      return Command_Palette_Availability_Filter is
   begin
      return Availability_Filter_State;
   end Current_Availability_Filter;

   procedure Set_Category_Filter_Label (Label : String) is
   begin
      Category_Filter_Active := Label'Length > 0;
      Category_Filter_Label_State := To_Unbounded_String (Label);
   end Set_Category_Filter_Label;

   procedure Clear_Category_Filter is
   begin
      Category_Filter_Active := False;
      Category_Filter_Label_State := Null_Unbounded_String;
   end Clear_Category_Filter;

   function Has_Category_Filter return Boolean is
   begin
      return Category_Filter_Active;
   end Has_Category_Filter;

   function Current_Category_Filter_Label return String is
   begin
      return To_String (Category_Filter_Label_State);
   end Current_Category_Filter_Label;

   procedure Set_Destructive_Filter (Enabled : Boolean) is
   begin
      Destructive_Filter_State := Enabled;
   end Set_Destructive_Filter;

   function Destructive_Filter_Enabled return Boolean is
   begin
      return Destructive_Filter_State;
   end Destructive_Filter_Enabled;

   procedure Set_Keybinding_Filter
     (Filter : Command_Palette_Keybinding_Filter) is
   begin
      Keybinding_Filter_State := Filter;
   end Set_Keybinding_Filter;

   function Current_Keybinding_Filter return Command_Palette_Keybinding_Filter is
   begin
      return Keybinding_Filter_State;
   end Current_Keybinding_Filter;

   function Candidate_Passes_Transient_Filters
     (Candidate : Editor.Commands.Palette_Model.Command_Palette_Candidate) return Boolean
   is
      Category_Text : constant String := To_String (Candidate.Category_Label);
   begin
      case Availability_Filter_State is
         when Palette_All_Commands =>
            null;
         when Palette_Available_Only =>
            if not Candidate.Available then
               return False;
            end if;
         when Palette_Unavailable_Only =>
            if Candidate.Available then
               return False;
            end if;
      end case;

      if Category_Filter_Active
        and then Lower (Category_Text) /= Lower (To_String (Category_Filter_Label_State))
      then
         return False;
      end if;

      if Destructive_Filter_State
        and then not Editor.Commands.Classification.Is_Destructive_Command (Candidate.Id)
      then
         return False;
      end if;

      case Keybinding_Filter_State is
         when Palette_All_Keybinding_States =>
            null;
         when Palette_Bound_Commands_Only =>
            if not Candidate.Has_Keybinding then
               return False;
            end if;
         when Palette_Unbound_Bindable_Commands_Only =>
            declare
               D : constant Editor.Commands.Descriptors.Command_Descriptor :=
                 Editor.Commands.Descriptors.Descriptor (Candidate.Id);
            begin
               if (not D.Bindable) or else Candidate.Has_Keybinding then
                  return False;
               end if;
            end;
      end case;

      return True;
   end Candidate_Passes_Transient_Filters;

   function Descriptor_Passes_Transient_Metadata_Filters
     (Descriptor : Editor.Commands.Descriptors.Command_Descriptor) return Boolean
   is
      Binding : constant Editor.Keybindings.Command_Keybinding_Info :=
        Editor.Keybindings.Primary_Binding_For_Command (Descriptor.Id);
      Category_Text : constant String :=
        Editor.Commands.Descriptors.Discoverability_Category_Label (Descriptor.Id);
   begin
      if Category_Filter_Active
        and then Lower (Category_Text) /= Lower (To_String (Category_Filter_Label_State))
      then
         return False;
      end if;

      if Destructive_Filter_State
        and then not Editor.Commands.Classification.Is_Destructive_Command (Descriptor.Id)
      then
         return False;
      end if;

      case Keybinding_Filter_State is
         when Palette_All_Keybinding_States =>
            null;
         when Palette_Bound_Commands_Only =>
            if (not Descriptor.Bindable) or else not Binding.Has_Binding then
               return False;
            end if;
         when Palette_Unbound_Bindable_Commands_Only =>
            if (not Descriptor.Bindable) or else Binding.Has_Binding then
               return False;
            end if;
      end case;

      return True;
   end Descriptor_Passes_Transient_Metadata_Filters;

end Editor.Command_Palette.Filters;
