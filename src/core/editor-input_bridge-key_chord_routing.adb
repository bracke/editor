with Editor.Input_Bridge.Active_Find_Key_Handlers;
with Editor.Input_Bridge.Build_UI_Key_Handlers;
with Editor.Input_Bridge.Diagnostics_Focus_Key_Handlers;
with Editor.Input_Bridge.File_Tree_Key_Handlers;
with Editor.Input_Bridge.Guided_Prompt_Key_Handlers;
with Editor.Input_Bridge.Keybinding_Handlers;
with Editor.Input_Bridge.Panel_Focus_Key_Handlers;
with Editor.Input_Bridge.Pending_Transition_Key_Handlers;
with Editor.Input_Bridge.Semantic_Popup_Key_Handlers;
with Editor.Input_Bridge.Settings_Handlers;
with Editor.Panel_Focus;

package body Editor.Input_Bridge.Key_Chord_Routing is

   function Handle_Pre_Bound_Chord
     (S                            : in out Editor.State.State_Type;
      Chord                        : Editor.Keybindings.Key_Chord;
      Accept_Guided_Prompt_Enter   : not null access procedure;
      Report_Info                  : not null access procedure (Text : String);
      Execute_Command_With_Shift   : not null access procedure
        (Id : Editor.Commands.Command_Id; Shift : Boolean);
      Execute_Default_Command      : not null access procedure
        (Id : Editor.Commands.Command_Id);
      Execute_Active_Find_Previous : not null access procedure;
      Hide_Active_Find             : not null access procedure)
      return Boolean
   is
   begin
      if Editor.Input_Bridge.Guided_Prompt_Key_Handlers.Handle_Guided_Prompt_Key
        (S, Chord, Accept_Guided_Prompt_Enter, Report_Info)
      then
         return True;
      end if;

      if Editor.Input_Bridge.Pending_Transition_Key_Handlers
        .Handle_Pending_Transition_Key
          (S, Chord, Execute_Command_With_Shift, Report_Info)
      then
         return True;
      end if;

      if Editor.Input_Bridge.Keybinding_Handlers.Handle_Keybinding_Chord
        (Chord, Report_Info)
      then
         return True;
      end if;

      if Editor.Input_Bridge.Settings_Handlers.Handle_Settings_Chord
        (S, Chord, Report_Info)
      then
         return True;
      end if;

      if Editor.Input_Bridge.Active_Find_Key_Handlers.Handle_Active_Find_Key
        (S, Chord, Execute_Active_Find_Previous, Hide_Active_Find)
      then
         return True;
      end if;

      if Editor.Input_Bridge.Semantic_Popup_Key_Handlers.Handle_Semantic_Popup_Key
        (S, Chord, Execute_Default_Command)
      then
         return True;
      end if;

      if Editor.Input_Bridge.Build_UI_Key_Handlers.Handle_Build_UI_Tab_Key
        (S, Chord)
      then
         return True;
      end if;

      if Editor.Input_Bridge.Diagnostics_Focus_Key_Handlers
        .Handle_Suppressed_Diagnostics_Key (S, Chord, Report_Info)
      then
         return True;
      end if;

      return False;
   end Handle_Pre_Bound_Chord;

   function Handle_Focused_Surface_Pre_Bound_Chord
     (S                       : in out Editor.State.State_Type;
      Chord                   : Editor.Keybindings.Key_Chord;
      Execute_Default_Command : not null access procedure
        (Id : Editor.Commands.Command_Id))
      return Boolean
   is
   begin
      if Chord.Modifiers.Ctrl
        or else Chord.Modifiers.Alt
        or else Chord.Modifiers.Meta
      then
         return False;
      end if;

      if Editor.Panel_Focus.File_Tree_Has_Focus (S.Panel_Focus) then
         declare
            Result : constant
              Editor.Input_Bridge.File_Tree_Key_Handlers.Focused_Key_Result :=
                Editor.Input_Bridge.File_Tree_Key_Handlers
                  .Handle_File_Tree_Focused_Surface_Key
                    (S, Chord, Execute_Default_Command);
         begin
            case Result is
               when Editor.Input_Bridge.File_Tree_Key_Handlers.File_Tree_Key_Handled =>
                  return True;
               when Editor.Input_Bridge.File_Tree_Key_Handlers.File_Tree_Key_Not_Handled =>
                  return False;
               when Editor.Input_Bridge.File_Tree_Key_Handlers.File_Tree_Not_Focused =>
                  null;
            end case;
         end;
      elsif S.Latest_Build_Result_Focused
        or else S.Latest_Build_Output_Details.Build_Output_Details_Focused
      then
         declare
            Result : constant
              Editor.Input_Bridge.Build_UI_Key_Handlers.Focused_Key_Result :=
                Editor.Input_Bridge.Build_UI_Key_Handlers
                  .Handle_Build_UI_Focused_Surface_Key
                    (S, Chord, Execute_Default_Command);
         begin
            case Result is
               when Editor.Input_Bridge.Build_UI_Key_Handlers.Build_UI_Key_Handled =>
                  return True;
               when Editor.Input_Bridge.Build_UI_Key_Handlers.Build_UI_Key_Not_Handled =>
                  return False;
               when Editor.Input_Bridge.Build_UI_Key_Handlers.Build_UI_Not_Focused =>
                  null;
            end case;
         end;
      elsif Editor.Input_Bridge.Panel_Focus_Key_Handlers
        .Handle_Focused_Surface_Key (S, Chord, Execute_Default_Command)
      then
         return True;
      end if;

      return False;
   end Handle_Focused_Surface_Pre_Bound_Chord;

end Editor.Input_Bridge.Key_Chord_Routing;
