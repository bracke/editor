with Editor.Command_Execution;
with Editor.Executor.Semantic_Completion_Commands;
with Editor.Executor.Semantic_Commands;

package body Editor.Executor.Semantic_Routing_Commands is

   procedure Execute_Semantic_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
      Result : constant Editor.Command_Execution.Command_Execution_Result :=
        Execute_Semantic_Result_Command (S, Cmd);
      pragma Unreferenced (Result);
   begin
      null;
   end Execute_Semantic_Kind;

   function Execute_Semantic_Result_Command
     (S  : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
      return Editor.Command_Execution.Command_Execution_Result
   is
      use Editor.Commands;

      function Id_From_Kind
        (Kind : Command_Kind) return Command_Id
      is
      begin
         case Kind is
            when Goto_Declaration =>
               return Command_Goto_Declaration;
            when Goto_Body =>
               return Command_Goto_Body;
            when Goto_Spec =>
               return Command_Goto_Spec;
            when Find_References =>
               return Command_Find_References;
            when Workspace_Symbols =>
               return Command_Workspace_Symbols;
            when Show_Hover =>
               return Command_Show_Hover;
            when Show_Completions =>
               return Command_Show_Completions;
            when Rename_Symbol_Preview =>
               return Command_Rename_Symbol_Preview;
            when Rename_Symbol_Apply =>
               return Command_Rename_Symbol_Apply;
            when Semantic_Refresh_Buffer =>
               return Command_Semantic_Refresh_Buffer;
            when Semantic_Refresh_Project_Index =>
               return Command_Semantic_Refresh_Project_Index;
            when Language_Index_Clear =>
               return Command_Language_Index_Clear;
            when Language_Index_Status =>
               return Command_Language_Index_Status;
            when Semantic_Completion_Select_Next =>
               return Command_Semantic_Completion_Select_Next;
            when Semantic_Completion_Select_Previous =>
               return Command_Semantic_Completion_Select_Previous;
            when Semantic_Completion_Accept =>
               return Command_Semantic_Completion_Accept;
            when Semantic_Popup_Dismiss =>
               return Command_Semantic_Popup_Dismiss;
            when others =>
               raise Program_Error with
                 "unsupported semantic result command kind: " &
                 Editor.Commands.Command_Kind'Image (Kind);
         end case;
      end Id_From_Kind;

      Id : constant Command_Id := Id_From_Kind (Cmd.Kind);
   begin
      case Cmd.Kind is
         when Goto_Declaration
            | Goto_Body
            | Goto_Spec
            | Find_References
            | Workspace_Symbols
            | Show_Hover
            | Show_Completions
            | Rename_Symbol_Preview
            | Rename_Symbol_Apply
            | Semantic_Refresh_Buffer
            | Semantic_Refresh_Project_Index
            | Language_Index_Clear
            | Language_Index_Status =>
            return Editor.Executor.Semantic_Commands.Execute_Semantic_Command
              (S, Id, Cmd);

         when Semantic_Completion_Select_Next
            | Semantic_Completion_Select_Previous
            | Semantic_Completion_Accept
            | Semantic_Popup_Dismiss =>
            Editor.Executor.Semantic_Completion_Commands
              .Execute_Semantic_Completion_Kind (S, Cmd.Kind);
            return Editor.Command_Execution.Executed (Id);

         when others =>
            raise Program_Error with "unsupported semantic result command";
      end case;
   end Execute_Semantic_Result_Command;

end Editor.Executor.Semantic_Routing_Commands;
