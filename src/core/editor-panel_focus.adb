package body Editor.Panel_Focus is

   procedure Clear
     (State : in out Panel_Focus_State)
   is
   begin
      State.Current_Target := Editor_Text_Focus;
      State.Current_Content := No_Bottom_Focus;
   end Clear;

   function Target
     (State : Panel_Focus_State) return Focus_Target
   is
   begin
      return State.Current_Target;
   end Target;

   function Bottom_Content
     (State : Panel_Focus_State) return Bottom_Focus_Content
   is
   begin
      return State.Current_Content;
   end Bottom_Content;

   function Editor_Text_Has_Focus
     (State : Panel_Focus_State) return Boolean
   is
   begin
      return State.Current_Target = Editor_Text_Focus;
   end Editor_Text_Has_Focus;

   function Bottom_Panel_Has_Focus
     (State : Panel_Focus_State) return Boolean
   is
   begin
      return State.Current_Target = Bottom_Panel_Focus
        and then State.Current_Content /= No_Bottom_Focus;
   end Bottom_Panel_Has_Focus;

   function File_Tree_Has_Focus
     (State : Panel_Focus_State) return Boolean
   is
   begin
      return State.Current_Target = File_Tree_Focus;
   end File_Tree_Has_Focus;

   procedure Focus_Editor_Text
     (State : in out Panel_Focus_State)
   is
   begin
      State.Current_Target := Editor_Text_Focus;
      State.Current_Content := No_Bottom_Focus;
   end Focus_Editor_Text;

   procedure Focus_File_Tree
     (State : in out Panel_Focus_State)
   is
   begin
      State.Current_Target := File_Tree_Focus;
      State.Current_Content := No_Bottom_Focus;
   end Focus_File_Tree;

   procedure Focus_Bottom_Panel
     (State   : in out Panel_Focus_State;
      Content : Bottom_Focus_Content)
   is
   begin
      if Content = No_Bottom_Focus then
         Focus_Editor_Text (State);
      else
         State.Current_Target := Bottom_Panel_Focus;
         State.Current_Content := Content;
      end if;
   end Focus_Bottom_Panel;

   procedure Clear_Bottom_Focus
     (State : in out Panel_Focus_State)
   is
   begin
      Focus_Editor_Text (State);
   end Clear_Bottom_Focus;

end Editor.Panel_Focus;
