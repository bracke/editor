package Editor.Panel_Focus is

   type Focus_Target is
     (Editor_Text_Focus,
      File_Tree_Focus,
      Bottom_Panel_Focus);

   type Bottom_Focus_Content is
     (No_Bottom_Focus,
      Problems_Focus,
      Search_Results_Focus);

   type Panel_Focus_State is private;

   procedure Clear
     (State : in out Panel_Focus_State);

   function Target
     (State : Panel_Focus_State) return Focus_Target;

   function Bottom_Content
     (State : Panel_Focus_State) return Bottom_Focus_Content;

   function Editor_Text_Has_Focus
     (State : Panel_Focus_State) return Boolean;

   function Bottom_Panel_Has_Focus
     (State : Panel_Focus_State) return Boolean;

   function File_Tree_Has_Focus
     (State : Panel_Focus_State) return Boolean;

   procedure Focus_Editor_Text
     (State : in out Panel_Focus_State);

   procedure Focus_File_Tree
     (State : in out Panel_Focus_State);

   procedure Focus_Bottom_Panel
     (State   : in out Panel_Focus_State;
      Content : Bottom_Focus_Content);

   procedure Clear_Bottom_Focus
     (State : in out Panel_Focus_State);

private
   type Panel_Focus_State is record
      Current_Target  : Focus_Target := Editor_Text_Focus;
      Current_Content : Bottom_Focus_Content := No_Bottom_Focus;
   end record;

end Editor.Panel_Focus;
