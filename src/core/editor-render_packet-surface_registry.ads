package Editor.Render_Packet.Surface_Registry is

   type Surface_Id is
     (Tab_Bar_Surface,
      File_Tree_Surface,
      Feature_Panel_Surface,
      Keybinding_Management_Surface,
      Bookmarks_Surface,
      Build_UI_Surface);

   type Surface_Layer_Group is
     (Chrome_Surface_Group,
      Editor_Text_Surface_Group,
      Panel_Surface_Group,
      Overlay_Surface_Group);

   subtype Surface_Name is String (1 .. 32);

   type Surface_Renderer is record
      Id    : Surface_Id;
      Name  : Surface_Name;
      Group : Surface_Layer_Group;
   end record;

   procedure Build_Render_Packet
     (Out_Packet : out Render_Packet);

end Editor.Render_Packet.Surface_Registry;
