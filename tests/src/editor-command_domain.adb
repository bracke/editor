with AUnit.Assertions; use AUnit.Assertions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Commands;
with Editor.Keybindings;
with Editor.Messages;
with Editor.Panel_Focus;
with Editor.Overlay_Focus;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Recent_Projects;
with Editor.Settings;
with Editor.State;

package body Editor.Command_Domain is

   function Hash_String (Text : String; Seed : Natural := 17) return Natural is
      Modulus : constant Long_Long_Integer := 2_147_483_647;
      H       : Long_Long_Integer := Long_Long_Integer (Seed);
   begin
      for Ch of Text loop
         H := (H * 131 + Long_Long_Integer (Character'Pos (Ch))) mod Modulus;
      end loop;
      return Natural (H);
   end Hash_String;

   function Hash_Natural (H : Natural; N : Natural) return Natural is
   begin
      return Hash_String (Natural'Image (N), H);
   end Hash_Natural;

   function Hash_Boolean (H : Natural; Value : Boolean) return Natural is
   begin
      return Hash_String ((if Value then "true" else "false"), H);
   end Hash_Boolean;

   function Settings_Fingerprint
     (S : Editor.State.State_Type) return Natural
   is
      H : Natural := 19;
   begin
      H := Hash_Natural (H, Editor.Settings.Version (S.Settings));
      H := Hash_String (Editor.Settings.Theme_Setting_Kind'Image
        (Editor.Settings.Theme_Mode (S.Settings)), H);
      H := Hash_String (Editor.Settings.Theme_Id (S.Settings), H);
      H := Hash_Boolean (H, Editor.Settings.Has_Line_Number_Mode (S.Settings));
      H := Hash_String (Editor.Settings.Line_Number_Mode_Name (S.Settings), H);
      H := Hash_String (Editor.Settings.Cursor_Style_Name (S.Settings), H);
      H := Hash_Boolean (H, Editor.Settings.Cursor_Blink (S.Settings));
      H := Hash_Boolean (H, Editor.Settings.Minimap_Visible (S.Settings));
      H := Hash_Boolean (H, Editor.Settings.Scrollbars_Visible (S.Settings));
      H := Hash_Boolean
        (H, Editor.Settings.Command_Palette_Show_Unavailable (S.Settings));
      H := Hash_Boolean
        (H, Editor.Settings.Command_Palette_Show_Keybindings (S.Settings));
      H := Hash_Boolean
        (H, Editor.Settings.Command_Palette_Show_Selected_Description (S.Settings));
      declare
         Runtime : constant Editor.Settings.Settings_State := Editor.Settings.Current;
      begin
         H := Hash_Boolean (H, Runtime.Show_Minimap);
         H := Hash_Boolean (H, Runtime.Show_Line_Numbers);
         H := Hash_Boolean (H, Runtime.Highlight_Current_Line);
         H := Hash_Boolean (H, Runtime.Highlight_Current_Gutter);
         H := Hash_Boolean (H, Runtime.Cursor_Blink_Enabled);
         H := Hash_Boolean (H, Runtime.Use_Syntax_Colouring);
         H := Hash_Boolean (H, Runtime.Show_Diagnostics);
      end;
      return H;
   end Settings_Fingerprint;

   function Active_Keybindings_Fingerprint return Natural is
      H    : Natural := 23;
      Info : Editor.Keybindings.Command_Keybinding_Info;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         declare
            Id : constant Editor.Commands.Command_Id := Editor.Commands.Command_At (I);
         begin
            H := Hash_String (Editor.Commands.Stable_Command_Name (Id), H);
            H := Hash_Natural
              (H, Editor.Keybindings.Binding_Count_For_Command (Id));
            Info := Editor.Keybindings.Primary_Binding_For_Command (Id);
            H := Hash_Boolean (H, Info.Has_Binding);
            if Info.Has_Binding then
               H := Hash_String (To_String (Info.Display), H);
            end if;
         end;
      end loop;
      return H;
   end Active_Keybindings_Fingerprint;

   function Command_Metadata_Fingerprint return Natural is
      H : Natural := 29;
      D : Editor.Commands.Command_Descriptor;
   begin
      for I in 1 .. Editor.Commands.Command_Count loop
         D := Editor.Commands.Descriptor (Editor.Commands.Command_At (I));
         H := Hash_String (Editor.Commands.Command_Id'Image (D.Id), H);
         H := Hash_String (Editor.Commands.Stable_Command_Name (D.Id), H);
         H := Hash_String (To_String (D.Name), H);
         H := Hash_String (To_String (D.Description), H);
         H := Hash_String (Editor.Commands.Command_Category'Image (D.Category), H);
         H := Hash_String (Editor.Commands.Command_Visibility'Image (D.Visibility), H);
         H := Hash_Boolean (H, D.Bindable);
         H := Hash_Boolean (H, D.Destructive);
         H := Hash_Boolean (H, D.Lifecycle);
         H := Hash_Boolean (H, D.Configuration);
      end loop;
      return H;
   end Command_Metadata_Fingerprint;

   function Summary
     (S : Editor.State.State_Type) return Command_Domain_Summary
   is
   begin
      return
        (Buffer_Count              => Editor.Buffers.Global_Count,
         Dirty_Buffer_Count        => Editor.Buffers.Global_Dirty_Buffer_Count,
         Has_Project               => Editor.Project.Has_Project (S.Project),
         Recent_Project_Count      => Editor.Recent_Projects.Count (S.Recent_Projects),
         Recent_Project_Selection  => S.Recent_Project_Selected_Index,
         Has_Pending_Transition    =>
           Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
         Settings_Fingerprint      => Settings_Fingerprint (S),
         Keybindings_Fingerprint   => Active_Keybindings_Fingerprint,
         Message_Count             => Editor.Messages.Count (S.Messages),
         Search_Fingerprint        =>
           Hash_String (To_String (S.Active_Find_Query)),
         Panel_Fingerprint         =>
           Hash_String
             (Editor.Panel_Focus.Focus_Target'Image (Editor.Panel_Focus.Target (S.Panel_Focus)) & ":" &
              Editor.Overlay_Focus.Overlay_Target'Image (Editor.Overlay_Focus.Active_Overlay (S.Overlay_Focus))));
   end Summary;

   procedure Check
     (Changed : Boolean;
      Allowed : Boolean;
      Domain  : Command_Side_Effect_Domain;
      Context : String)
   is
   begin
      if Changed and then not Allowed then
         Assert (False,
           Context & ": unexpected mutation in " &
           Command_Side_Effect_Domain'Image (Domain));
      end if;
   end Check;

   procedure Assert_Command_Mutates_Only
     (Before  : Editor.State.State_Type;
      After   : Editor.State.State_Type;
      Allowed : Command_Side_Effect_Domain_Set;
      Context : String)
   is
      B : constant Command_Domain_Summary := Summary (Before);
      A : constant Command_Domain_Summary := Summary (After);
   begin
      Check (B.Buffer_Count /= A.Buffer_Count,
             Allowed (Domain_Buffers), Domain_Buffers, Context);
      Check (B.Dirty_Buffer_Count /= A.Dirty_Buffer_Count,
             Allowed (Domain_Dirty_State), Domain_Dirty_State, Context);
      Check (B.Has_Project /= A.Has_Project,
             Allowed (Domain_Project), Domain_Project, Context);
      Check (B.Recent_Project_Count /= A.Recent_Project_Count
             or else B.Recent_Project_Selection /= A.Recent_Project_Selection,
             Allowed (Domain_Recent_Projects), Domain_Recent_Projects, Context);
      Check (B.Has_Pending_Transition /= A.Has_Pending_Transition,
             Allowed (Domain_Pending_Transition), Domain_Pending_Transition, Context);
      Check (B.Settings_Fingerprint /= A.Settings_Fingerprint,
             Allowed (Domain_Settings_Runtime), Domain_Settings_Runtime, Context);
      Check (B.Keybindings_Fingerprint /= A.Keybindings_Fingerprint,
             Allowed (Domain_Keybindings_Runtime), Domain_Keybindings_Runtime, Context);
      Check (B.Message_Count /= A.Message_Count,
             Allowed (Domain_Messages), Domain_Messages, Context);
      Check (B.Search_Fingerprint /= A.Search_Fingerprint,
             Allowed (Domain_Search_State), Domain_Search_State, Context);
      Check (B.Panel_Fingerprint /= A.Panel_Fingerprint,
             Allowed (Domain_Panel_State), Domain_Panel_State, Context);
   end Assert_Command_Mutates_Only;

end Editor.Command_Domain;
