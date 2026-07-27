with Editor.Diagnostics;
with Editor.Feature_Diagnostics;
with Editor.Feature_Messages;
with Editor.Feature_Panel;
with Editor.Feature_Search_Results;
with Editor.Messages;
with Editor.Overlay_Focus;
with Editor.Panel_Focus;
with Editor.Problems;
with Editor.Search_Results;

package Editor.State_Panel is

   type Active_Diagnostic_State is record
      Has_Active : Boolean := False;
      Index      : Editor.Diagnostics.Diagnostic_Index :=
        Editor.Diagnostics.No_Diagnostic;
   end record;

   type Panel_Runtime_State is record
      Diagnostics       : Editor.Diagnostics.Diagnostic_Vectors.Vector;
      Active_Diagnostic : Active_Diagnostic_State;
      Feature_Panel     : Editor.Feature_Panel.Feature_Panel_State;
      Feature_Messages  : Editor.Feature_Messages.Message_Feature_State;
      Feature_Search_Results :
        Editor.Feature_Search_Results.Search_Results_Feature_State;
      Feature_Diagnostics :
        Editor.Feature_Diagnostics.Diagnostics_Feature_State;
      Messages           : Editor.Messages.Message_State;
      Search_Results_View : Editor.Search_Results.Search_Results_View_State;
      Problems_View       : Editor.Problems.Problems_View_State;
      Panel_Focus         : Editor.Panel_Focus.Panel_Focus_State;
      Overlay_Focus       : Editor.Overlay_Focus.Overlay_Focus_State;
   end record;

end Editor.State_Panel;
