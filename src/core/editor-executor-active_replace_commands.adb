with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Input_Field;
with Editor.Overlay_Focus;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Active_Replace_Commands is

   procedure Clear_Active_Replace_State
     (S : in out Editor.State.State_Type)
   is
   begin
      S.Active_Replace_Prompt := False;
      S.Active_Replace_Text := Null_Unbounded_String;
      S.Active_Replace_Error_Message := Null_Unbounded_String;
   end Clear_Active_Replace_State;

   function Is_Valid_Replace_Text (Text : String) return Boolean is
   begin
      for Ch of Text loop
         if Ch = Character'Val (10) or else Ch = Character'Val (13) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Replace_Text;

   procedure Report_Invalid_Replace_Text
     (S : in out Editor.State.State_Type)
   is
   begin
      S.Active_Replace_Error_Message :=
        To_Unbounded_String ("Replacement text must be single-line");
      Report_Warning (S, "Replacement text must be single-line");
      Editor.Render_Cache.Invalidate_All;
   end Report_Invalid_Replace_Text;

   procedure Execute_Replace_Show
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.Activate_Overlay
        (S, Editor.Overlay_Focus.Active_Find_Prompt_Overlay);
      S.Active_Find_Prompt := True;
      S.Active_Replace_Prompt := True;
      S.Active_Replace_Error_Message := Null_Unbounded_String;
      Editor.Input_Field.Set_Text (S.Active_Find_Input, To_String (S.Active_Find_Query));
      Report_Info (S, "Replace shown");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Replace_Show;

   procedure Execute_Replace_Hide
     (S : in out Editor.State.State_Type)
   is
   begin
      Clear_Active_Replace_State (S);
      Report_Info (S, "Replace hidden");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Replace_Hide;

   procedure Execute_Replace_Toggle
     (S : in out Editor.State.State_Type)
   is
   begin
      if S.Active_Replace_Prompt then
         Execute_Replace_Hide (S);
      else
         Execute_Replace_Show (S);
      end if;
   end Execute_Replace_Toggle;

   procedure Execute_Replace_Set_Text
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Editor.Executor.Activate_Overlay
        (S, Editor.Overlay_Focus.Active_Find_Prompt_Overlay);
      S.Active_Find_Prompt := True;
      S.Active_Replace_Prompt := True;

      if not Is_Valid_Replace_Text (Text) then
         Report_Invalid_Replace_Text (S);
         return;
      end if;

      S.Active_Replace_Text := To_Unbounded_String (Text);
      S.Active_Replace_Error_Message := Null_Unbounded_String;
      Report_Info (S, "Replace text set");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Replace_Set_Text;

   procedure Execute_Replace_Clear_Text
     (S : in out Editor.State.State_Type)
   is
   begin
      if Length (S.Active_Replace_Text) = 0
        and then Length (S.Active_Replace_Error_Message) = 0
      then
         Report_Info (S, "No replacement text to clear");
      else
         S.Active_Replace_Text := Null_Unbounded_String;
         S.Active_Replace_Error_Message := Null_Unbounded_String;
         Report_Info (S, "Replace text cleared");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Replace_Clear_Text;

end Editor.Executor.Active_Replace_Commands;
