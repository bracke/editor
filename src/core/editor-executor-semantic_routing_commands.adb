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
              (S, Cmd.Kind, Cmd);

         when Semantic_Completion_Select_Next =>
            Editor.Executor.Semantic_Completion_Commands
              .Execute_Semantic_Completion_Select (S, Next => True);
            return Editor.Command_Execution.Executed (Cmd.Kind);

         when Semantic_Completion_Select_Previous =>
            Editor.Executor.Semantic_Completion_Commands
              .Execute_Semantic_Completion_Select (S, Next => False);
            return Editor.Command_Execution.Executed (Cmd.Kind);

         when Semantic_Completion_Accept =>
            Editor.Executor.Semantic_Completion_Commands
              .Execute_Semantic_Completion_Accept (S);
            return Editor.Command_Execution.Executed (Cmd.Kind);

         when Semantic_Popup_Dismiss =>
            Editor.Executor.Semantic_Completion_Commands
              .Execute_Semantic_Popup_Dismiss (S);
            return Editor.Command_Execution.Executed (Cmd.Kind);

         when others =>
            raise Program_Error with "unsupported semantic result command";
      end case;
   end Execute_Semantic_Result_Command;

end Editor.Executor.Semantic_Routing_Commands;
