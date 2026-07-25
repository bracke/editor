with Editor.Feature_Panel;

package Editor.Outline.Projection is

   function To_Item
     (Kind        : Outline_Item_Kind;
      Label       : String;
      Detail      : String;
      Depth       : Natural;
      Target_Kind  : Outline_Target_Kind := No_Target;
      Buffer_Token : Natural := 0;
      Line         : Natural := 0;
      Column       : Natural := 0) return Outline_Item;

   function Kind_Text (Kind : Outline_Item_Kind) return String;

   function Invariant_Holds
     (Outline : Outline_State) return Boolean;
   function Debug_Summary
     (Outline : Outline_State) return String;
   procedure Assert_Outline_State_Consistent
     (Outline : Outline_State);
   procedure Clear
     (Outline : in out Outline_State);
   procedure Reset_Outline_For_Buffer_Close
     (Outline      : in out Outline_State;
      Buffer_Token : Natural);
   procedure Reset_Outline_For_Project_Close
     (Outline : in out Outline_State);
   procedure Reset_Outline_For_Workspace_Close
     (Outline : in out Outline_State);
   procedure Reset_Outline_For_Unsupported_Content
     (Outline : in out Outline_State);
   procedure Reset_Outline_For_Extraction_Failure
     (Outline : in out Outline_State;
      Message : String);
   procedure Mark_No_Active_Buffer
     (Outline : in out Outline_State);
   procedure Begin_Extraction
     (Outline  : in out Outline_State;
      Snapshot : Outline_Snapshot_Identity);
   function Next_Request_Token
     (Outline : Outline_State) return Natural;
   function Snapshot_Is_Current
     (Outline  : Outline_State;
      Snapshot : Outline_Snapshot_Identity) return Boolean;
   procedure Mark_Stale_Result
     (Outline : in out Outline_State;
      Message : String := "Outline result discarded: stale buffer snapshot");
   procedure Mark_Extraction_Failed
     (Outline : in out Outline_State;
      Message : String := "Outline extraction failed");
   procedure Mark_Unsupported
     (Outline : in out Outline_State;
      Message : String := "Outline unavailable for this buffer");
   procedure Reset_For_Project_Close
     (Outline : in out Outline_State);
   procedure Reset_For_Buffer_Change
     (Outline : in out Outline_State);
   procedure Mark_For_Buffer_Change
     (Outline : in out Outline_State);
   function Is_Current_For_Buffer
     (Outline         : Outline_State;
      Buffer_Token    : Natural;
      Buffer_Revision : Natural) return Boolean;
   function Is_Stale_For_Buffer
     (Outline         : Outline_State;
      Buffer_Token    : Natural;
      Buffer_Revision : Natural) return Boolean;
   function Freshness_For_Active_Buffer
     (Outline         : Outline_State;
      Buffer_Token    : Natural;
      Buffer_Revision : Natural) return Outline_Freshness;
   function Source_Buffer_Token
     (Outline : Outline_State) return Natural;
   function Source_Buffer_Revision
     (Outline : Outline_State) return Natural;
   function Refresh
     (Outline : in out Outline_State;
      Source  : Outline_Refresh_Source) return Outline_Refresh_Result;
   procedure Replace_Items
     (Outline : in out Outline_State;
      Items   : Outline_Item_Array);
   procedure Set_Rows_From_Outline
     (Outline : Outline_State;
      Panel   : in out Editor.Feature_Panel.Feature_Panel_State);
   function Item_Count
     (Outline : Outline_State) return Natural;
   function Has_Items
     (Outline : Outline_State) return Boolean;
   function Source_Class
     (Outline : Outline_State) return Outline_Source_Class;
   function Last_Extraction_Source_Class
     (Outline : Outline_State) return Outline_Source_Class;
   function Last_Extraction_Message
     (Outline : Outline_State) return String;
   function Last_Extraction_Buffer_Label
     (Outline : Outline_State) return String;
   function Last_Extraction_Item_Count
     (Outline : Outline_State) return Natural;
   function Item_Label
     (Outline : Outline_State;
      Index   : Positive) return String;
   function Item_Detail
     (Outline : Outline_State;
      Index   : Positive) return String;
   function Item_Depth
     (Outline : Outline_State;
      Index   : Positive) return Natural;
   function Item_Kind
     (Outline : Outline_State;
      Index   : Positive) return Outline_Item_Kind;
   function Item_Target_Kind
     (Outline : Outline_State;
      Index   : Positive) return Outline_Target_Kind;
   function Item_Buffer_Token
     (Outline : Outline_State;
      Index   : Positive) return Natural;
   function Item_Line
     (Outline : Outline_State;
      Index   : Positive) return Natural;
   function Item_Column
     (Outline : Outline_State;
      Index   : Positive) return Natural;
   function Summary
     (Outline : Outline_State) return Outline_Summary;
   function Fingerprint
     (Outline : Outline_State) return Natural;
   function Projection_Invariant_Holds
     (Outline : Outline_State;
      Panel   : Editor.Feature_Panel.Feature_Panel_State) return Boolean;
   procedure Assert_Outline_Projection_Consistent
     (Outline : Outline_State;
      Panel   : Editor.Feature_Panel.Feature_Panel_State);

end Editor.Outline.Projection;
