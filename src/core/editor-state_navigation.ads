with Editor.Bookmarks;
with Editor.Navigation_History;
with Editor.Recent_Buffers;

package Editor.State_Navigation is

   type Navigation_Runtime_State is record
      History        : Editor.Navigation_History.Navigation_History_State;
      Recent_Buffers : Editor.Recent_Buffers.Recent_Buffer_State;
      Bookmarks      : Editor.Bookmarks.Bookmark_State;
   end record;

end Editor.State_Navigation;
