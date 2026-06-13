with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Feature_Integration is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Category;

   procedure Append_Failure
     (Result  : in out Feature_Integration_Result;
      Command : Editor.Commands.Command_Id;
      Message : String)
   is
   begin
      Result.Failures := Result.Failures + 1;
      if Length (Result.Text) = 0 then
         Append (Result.Text, "Feature integration audit failed:");
      end if;
      Append (Result.Text, ASCII.LF & "  ");
      Append (Result.Text, Editor.Commands.Command_Id'Image (Command));
      Append (Result.Text, ": ");
      Append (Result.Text, Message);
   end Append_Failure;

   procedure Clear
     (Result : in out Feature_Integration_Result)
   is
   begin
      Result.Failures := 0;
      Result.Text := Null_Unbounded_String;
   end Clear;

   procedure Add_Failure
     (Result  : in out Feature_Integration_Result;
      Command : Editor.Commands.Command_Id;
      Message : String)
   is
   begin
      Append_Failure (Result, Command, Message);
   end Add_Failure;

   procedure Validate_Command_Contract
     (Result   : in out Feature_Integration_Result;
      Contract : Feature_Command_Contract)
   is
   begin
      if Contract.Command = Editor.Commands.No_Command then
         Add_Failure (Result, Contract.Command, "feature command has no command id");
      end if;

      if not Contract.Has_Descriptor then
         Add_Failure (Result, Contract.Command, "missing command descriptor");
      end if;

      if Contract.Bindable then
         if not Contract.Has_Stable_Name then
            Add_Failure (Result, Contract.Command, "bindable feature command has no stable name");
         elsif not Contract.Stable_Name_Round_Trips then
            Add_Failure (Result, Contract.Command, "bindable feature command stable name does not round-trip");
         end if;
      end if;

      if not Contract.Has_Availability then
         Add_Failure (Result, Contract.Command, "missing side-effect-free availability handler");
      end if;

      if not Contract.Has_Executor_Handling then
         Add_Failure (Result, Contract.Command, "missing Executor handling");
      end if;

      if Contract.Kind = Feature_Destructive
        and then not Contract.Destructive_Classified
      then
         Add_Failure (Result, Contract.Command, "destructive feature command lacks destructive classification");
      end if;

      if Contract.Kind = Feature_Lifecycle
        and then not Contract.Lifecycle_Classified
      then
         Add_Failure (Result, Contract.Command, "lifecycle feature command lacks lifecycle classification");
      end if;

      if Contract.Kind = Feature_Configuration
        and then not Contract.Configuration_Classified
      then
         Add_Failure (Result, Contract.Command, "configuration feature command lacks configuration classification");
      end if;
   end Validate_Command_Contract;

   procedure Validate_Route_Contract
     (Result   : in out Feature_Integration_Result;
      Contract : Feature_Route_Contract)
   is
   begin
      if Contract.Expected_Command /= Contract.Actual_Command then
         Add_Failure
           (Result, Contract.Expected_Command,
            "feature route dispatched wrong Command_Id; actual=" &
            Editor.Commands.Command_Id'Image (Contract.Actual_Command));
      end if;

      if not Contract.Reached_Executor then
         Add_Failure (Result, Contract.Expected_Command,
                      "feature route did not reach Executor");
      end if;

      if Contract.Mutated_Before_Executor then
         Add_Failure (Result, Contract.Expected_Command,
                      "feature route mutated state before Executor");
      end if;

      if Contract.Executor_Dispatch_Count > 1 then
         Add_Failure (Result, Contract.Expected_Command,
                      "feature route reached Executor more than once");
      end if;
   end Validate_Route_Contract;

   procedure Validate_Render_Projection
     (Result   : in out Feature_Integration_Result;
      Contract : Feature_Render_Projection_Contract)
   is
   begin
      if not Contract.Has_Explicit_Layer then
         Add_Failure (Result, Editor.Commands.No_Command,
                      "feature render projection has no explicit render layer");
      end if;

      if not Contract.Uses_Theme_Colours then
         Add_Failure (Result, Editor.Commands.No_Command,
                      "feature render projection does not use Theme colours/accessors");
      end if;

      if Contract.Mutates_Feature_State then
         Add_Failure (Result, Editor.Commands.No_Command,
                      "feature render projection mutates feature state");
      end if;

      if Contract.Mutates_Command_State then
         Add_Failure (Result, Editor.Commands.No_Command,
                      "feature render projection mutates command state");
      end if;

      if Contract.Mutates_Configuration_State then
         Add_Failure (Result, Editor.Commands.No_Command,
                      "feature render projection mutates configuration state");
      end if;

      if Contract.Mutates_Lifecycle_State then
         Add_Failure (Result, Editor.Commands.No_Command,
                      "feature render projection mutates lifecycle state");
      end if;

      if Contract.Corrupts_Existing_Layer_Order then
         Add_Failure (Result, Editor.Commands.No_Command,
                      "feature render projection corrupts existing layer order");
      end if;
   end Validate_Render_Projection;

   procedure Validate_Persistence_Contract
     (Result   : in out Feature_Integration_Result;
      Contract : Feature_Persistence_Contract)
   is
   begin
      if not Contract.Explicit_Scope_Declared then
         Add_Failure (Result, Editor.Commands.No_Command,
                      "feature persistence scope is not explicit");
      end if;

      if Contract.Persists_Dirty_Text then
         Add_Failure (Result, Editor.Commands.No_Command,
                      "feature persistence must not persist dirty text");
      end if;

      if Contract.Persists_Pending_State then
         Add_Failure (Result, Editor.Commands.No_Command,
                      "feature persistence must not persist pending transitions");
      end if;

      if Contract.Persists_To_Keybindings then
         Add_Failure (Result, Editor.Commands.No_Command,
                      "feature runtime/configuration state leaked into keybinding config");
      end if;

      if Contract.Persists_To_Settings and then not Contract.Explicit_Scope_Declared then
         Add_Failure (Result, Editor.Commands.No_Command,
                      "feature settings persistence must be explicitly mapped");
      end if;

      if Contract.Persists_To_Workspace and then not Contract.Explicit_Scope_Declared then
         Add_Failure (Result, Editor.Commands.No_Command,
                      "feature workspace persistence must be explicitly structural/session scoped");
      end if;
   end Validate_Persistence_Contract;


   procedure Validate_Reference_Feature_Panel
     (Result : in out Feature_Integration_Result)
   is
      Found : Boolean := False;
      Round : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Feature_Commands : constant array (Positive range <>) of Editor.Commands.Command_Id :=
        (Editor.Commands.Command_Toggle_Feature_Panel,
         Editor.Commands.Command_Show_Feature_Panel,
         Editor.Commands.Command_Hide_Feature_Panel,
         Editor.Commands.Command_Focus_Feature_Panel,
         Editor.Commands.Command_Clear_Feature_Panel,
         Editor.Commands.Command_Feature_Panel_Select_Next,
         Editor.Commands.Command_Feature_Panel_Select_Previous,
         Editor.Commands.Command_Feature_Panel_Open_Selected);
   begin
      for Id of Feature_Commands loop
         if not Editor.Commands.Has_Descriptor (Id) then
            Add_Failure (Result, Id, "Feature_Panel: missing descriptor");
         end if;

         if not Editor.Commands.Has_Availability_Handler (Id) then
            Add_Failure (Result, Id, "Feature_Panel: missing availability handler");
         end if;

         Round := Editor.Commands.Command_Id_From_Stable_Name
           (Editor.Commands.Stable_Command_Name (Id), Found);
         if not Found or else Round /= Id then
            Add_Failure (Result, Id,
                         "Feature_Panel: stable command name does not round-trip");
         end if;
      end loop;

      declare
         Removed_Found : Boolean := True;
         Removed_Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      begin
         Removed_Id := Editor.Commands.Command_Id_From_Stable_Name
           ("populate-feature-panel-placeholder", Removed_Found);
         if Removed_Found or else Removed_Id /= Editor.Commands.No_Command then
            Add_Failure
              (Result, Removed_Id,
               "Feature_Panel: removed placeholder population command must be removed");
         end if;
      end;
   end Validate_Reference_Feature_Panel;



   procedure Validate_Outline_Content_Foundation
     (Result : in out Feature_Integration_Result)
   is
      Found : Boolean := False;
      Round : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Outline_Commands : constant array (Positive range <>) of Editor.Commands.Command_Id :=
        (Editor.Commands.Command_Refresh_Outline,
         Editor.Commands.Command_Clear_Outline,
         Editor.Commands.Command_Show_Outline,
         Editor.Commands.Command_Focus_Outline,
         Editor.Commands.Command_Open_Selected_Outline_Item,
         Editor.Commands.Command_Select_Current_Outline_Symbol,
         Editor.Commands.Command_Reveal_Current_Outline_Symbol,
         Editor.Commands.Command_Select_Next_Outline_Item,
         Editor.Commands.Command_Select_Previous_Outline_Item);
   begin
      for Id of Outline_Commands loop
         if not Editor.Commands.Has_Descriptor (Id) then
            Add_Failure (Result, Id, "Outline: missing descriptor");
         end if;

         if not Editor.Commands.Has_Availability_Handler (Id) then
            Add_Failure (Result, Id, "Outline: missing availability handler");
         end if;

         Round := Editor.Commands.Command_Id_From_Stable_Name
           (Editor.Commands.Stable_Command_Name (Id), Found);
         if not Found or else Round /= Id then
            Add_Failure (Result, Id,
                         "Outline: stable command name does not round-trip");
         end if;

         if Editor.Commands.Category (Id) /= Editor.Commands.Panel_Category then
            Add_Failure (Result, Id, "Outline: command must remain in Panels category");
         end if;

         if Editor.Commands.Is_Configuration_Command (Id)
           or else Editor.Commands.Is_Lifecycle_Command (Id)
           or else Editor.Commands.Is_Destructive_Command (Id)
         then
            Add_Failure
              (Result, Id,
               "Outline: placeholder content commands must not be classified as configuration, lifecycle, or destructive");
         end if;
      end loop;
   end Validate_Outline_Content_Foundation;


   function Status
     (Result : Feature_Integration_Result)
      return Feature_Integration_Status
   is
   begin
      if Result.Failures = 0 then
         return Feature_Integration_Ok;
      else
         return Feature_Integration_Failed;
      end if;
   end Status;

   function Failure_Count
     (Result : Feature_Integration_Result) return Natural
   is
   begin
      return Result.Failures;
   end Failure_Count;

   function Summary
     (Result : Feature_Integration_Result) return String
   is
   begin
      if Result.Failures = 0 then
         return "Feature integration audit ok";
      end if;
      return To_String (Result.Text);
   end Summary;

end Editor.Feature_Integration;
