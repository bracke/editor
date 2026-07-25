with Editor.Feature_Panel;

package Editor.Outline.Selection is

   procedure Clear_Outline_Selection (Outline : in out Outline_State);
   procedure Select_Item
     (Outline : in out Outline_State;
      Index   : Natural);
   function Selected_Index
     (Outline : Outline_State) return Natural;
   function Has_Selected_Item
     (Outline : Outline_State) return Boolean;
   procedure Clear_Current_Symbol
     (Outline : in out Outline_State);
   procedure Set_Current_Symbol_Index
     (Outline : in out Outline_State;
      Index   : Natural);
   function Current_Symbol_Index
     (Outline : Outline_State) return Natural;
   function Has_Current_Symbol
     (Outline : Outline_State) return Boolean;
   function Current_Symbol_Label
     (Outline : Outline_State) return String;
   function Current_Symbol_Line
     (Outline : Outline_State) return Natural;
   function Find_Current_Symbol_For_Cursor
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1) return Natural;
   procedure Update_Current_Symbol_For_Cursor
     (Outline      : in out Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1);
   function Outline_Header_Text
     (Outline : Outline_State) return String;
   function Outline_Empty_State_Label
     (Outline : Outline_State) return String;
   function Is_Current_Symbol_Row
     (Outline : Outline_State;
      Index   : Positive) return Boolean;
   function Is_Selectable_Target_Row
     (Outline : Outline_State;
      Index   : Positive) return Boolean;
   function Has_Selectable_Filter_Match
     (Outline : Outline_State) return Boolean;
   function Navigable_Symbol_Count
     (Outline : Outline_State) return Natural;
   function Filtered_Navigable_Symbol_Count
     (Outline : Outline_State) return Natural;
   function Can_Reveal_Current_Symbol
     (Outline             : Outline_State;
      Panel               : Editor.Feature_Panel.Feature_Panel_State;
      Active_Buffer_Token : Natural) return Boolean;
   function Same_Outline_Target
     (Left, Right : Outline_Item) return Boolean;
   function Same_Outline_Symbol
     (Left, Right : Outline_Item) return Boolean;
   function Outline_Buffer_Identity_Matches
     (Outline      : Outline_State;
      Buffer_Token : Natural) return Boolean;
   function Has_Navigable_Symbol_For_Buffer
     (Outline      : Outline_State;
      Buffer_Token : Natural) return Boolean;
   function Selection_Preservation_Score
     (Previous, Candidate : Outline_Item) return Natural;
   function Find_Nearest_Item_For_Position
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1) return Natural;
   function Find_Next_Symbol_For_Position
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1;
      Wrap         : Boolean := True) return Natural;
   function Find_Previous_Symbol_For_Position
     (Outline      : Outline_State;
      Buffer_Token : Natural;
      Line         : Positive;
      Column       : Natural := 1;
      Wrap         : Boolean := True) return Natural;
   function Select_Next_Selectable
     (Outline : in out Outline_State) return Boolean;
   function Select_Previous_Selectable
     (Outline : in out Outline_State) return Boolean;

end Editor.Outline.Selection;
