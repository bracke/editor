with Editor.Feature_Panel;

package Editor.Outline.Activation is

   function Feature_Row_Maps_To_Item
     (Outline : Outline_State;
      Panel   : Editor.Feature_Panel.Feature_Panel_State;
      Row     : Positive) return Boolean;
   function Map_Panel_Row_To_Outline_Row
     (Outline                   : Outline_State;
      Panel                     : Editor.Feature_Panel.Feature_Panel_State;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0) return Natural;
   function Validate_Outline_Row_For_Selection
     (Outline                   : Outline_State;
      Panel                     : Editor.Feature_Panel.Feature_Panel_State;
      Row                       : Natural;
      Expected_Panel_Generation : Natural := 0) return Boolean;
   function Validate_Outline_Row_For_Activation
     (Outline                   : Outline_State;
      Panel                     : Editor.Feature_Panel.Feature_Panel_State;
      Row                       : Natural;
      Active_Buffer_Token       : Natural;
      Expected_Panel_Generation : Natural := 0) return Boolean;
   function Message_Outline_Refreshed return String;
   function Message_Outline_Cleared return String;
   function Message_Outline_Shown return String;
   function Message_Outline_Focused return String;
   function Message_Outline_Item_Has_No_Target return String;
   function Message_Outline_Refresh_Failed return String;
   function Message_Outline_No_Current_Symbol return String;
   function Message_Outline_Current_Symbol_Revealed return String;
   function Message_Outline_No_Active_Buffer return String;
   function Message_Outline_Unsupported_Buffer return String;
   function Message_Outline_No_Symbols return String;
   function Message_Outline_No_Matching_Symbols return String;
   function Message_Outline_No_Selected_Symbol return String;
   function Message_Outline_Stale_Result_Discarded return String;
   function Reason_No_Active_Buffer return String;
   function Reason_No_Outline_Items return String;
   function Reason_No_Outline_Item_Selected return String;
   function Reason_Outline_Belongs_To_Another_Buffer return String;
   function Reason_Feature_Panel_Hidden return String;
   function Reason_Feature_Panel_Already_Shown return String;
   function Reason_Feature_Panel_Already_Focused return String;

end Editor.Outline.Activation;
