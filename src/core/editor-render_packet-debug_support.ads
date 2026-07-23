with Editor.State;

package Editor.Render_Packet.Debug_Support is

   procedure Record_Debug_Text_For_Test (Text : String);

   procedure Clear_Debug_Text_For_Test;

   function Debug_Text_Contains_For_Test
     (Text : String) return Boolean;

   function Debug_Text_For_Test return String;

   function Audit_Buffer_Metadata_Render_Boundary
     return Buffer_Metadata_Render_Boundary_Audit;

   function Assert_Buffer_Metadata_Render_Boundary_Safe return Boolean;

   function Active_Find_Buffer_Token
     (S : Editor.State.State_Type) return Natural;

   function Active_Find_Source_Current
     (S : Editor.State.State_Type) return Boolean;

end Editor.Render_Packet.Debug_Support;
