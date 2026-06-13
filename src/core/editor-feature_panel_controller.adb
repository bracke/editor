with Editor.Outline;
with Editor.Feature_Messages;
with Editor.Feature_Search_Results;
with Editor.Feature_Diagnostics;

package body Editor.Feature_Panel_Controller is

   use type Editor.Feature_Panel.Feature_Id;


   function Has_Projection_Dispatch
     (Feature : Editor.Feature_Panel.Feature_Id) return Boolean
   is
   begin
      case Feature is
         when Editor.Feature_Panel.Outline_Feature =>
            return True;
         when Editor.Feature_Panel.Messages_Feature =>
            return True;
         when Editor.Feature_Panel.Search_Results_Feature =>
            return True;
         when Editor.Feature_Panel.Diagnostics_Feature =>
            return True;
         when Editor.Feature_Panel.Unknown_Feature =>
            return False;
      end case;
   end Has_Projection_Dispatch;

   function Has_Clear_Dispatch
     (Feature : Editor.Feature_Panel.Feature_Id) return Boolean
   is
   begin
      case Feature is
         when Editor.Feature_Panel.Outline_Feature =>
            return True;
         when Editor.Feature_Panel.Messages_Feature =>
            return True;
         when Editor.Feature_Panel.Search_Results_Feature =>
            return True;
         when Editor.Feature_Panel.Diagnostics_Feature =>
            return True;
         when Editor.Feature_Panel.Unknown_Feature =>
            return False;
      end case;
   end Has_Clear_Dispatch;

   function Has_Open_Dispatch
     (Feature : Editor.Feature_Panel.Feature_Id) return Boolean
   is
   begin
      case Feature is
         when Editor.Feature_Panel.Outline_Feature =>
            return True;
         when Editor.Feature_Panel.Messages_Feature =>
            return True;
         when Editor.Feature_Panel.Search_Results_Feature =>
            return True;
         when Editor.Feature_Panel.Diagnostics_Feature =>
            return True;
         when Editor.Feature_Panel.Unknown_Feature =>
            return False;
      end case;
   end Has_Open_Dispatch;

   function Has_Row_Action_Dispatch
     (Feature : Editor.Feature_Panel.Feature_Id) return Boolean
   is
   begin
      --  Row actions share the same active-feature row validation/open path in
      --  Phase 158. Keep this as a named audit seam so future features must
      --  explicitly declare action coverage instead of silently inheriting it.
      case Feature is
         when Editor.Feature_Panel.Outline_Feature =>
            return True;
         when Editor.Feature_Panel.Messages_Feature =>
            return True;
         when Editor.Feature_Panel.Search_Results_Feature =>
            return True;
         when Editor.Feature_Panel.Diagnostics_Feature =>
            return True;
         when Editor.Feature_Panel.Unknown_Feature =>
            return False;
      end case;
   end Has_Row_Action_Dispatch;

   function Has_Lifecycle_Dispatch
     (Feature : Editor.Feature_Panel.Feature_Id) return Boolean
   is
   begin
      case Feature is
         when Editor.Feature_Panel.Outline_Feature =>
            return True;
         when Editor.Feature_Panel.Messages_Feature =>
            return True;
         when Editor.Feature_Panel.Search_Results_Feature =>
            return True;
         when Editor.Feature_Panel.Diagnostics_Feature =>
            return True;
         when Editor.Feature_Panel.Unknown_Feature =>
            return False;
      end case;
   end Has_Lifecycle_Dispatch;

   function Feature_Dispatch_Covers_All_Features return Boolean
   is
      Feature : Editor.Feature_Panel.Feature_Id;
   begin
      for I in 1 .. Editor.Feature_Panel.Feature_Descriptor_Count loop
         Feature := Editor.Feature_Panel.Descriptor_Id (I);
         if not Editor.Feature_Panel.Is_Known_Feature (Feature)
           or else not Has_Projection_Dispatch (Feature)
           or else not Has_Clear_Dispatch (Feature)
           or else not Has_Open_Dispatch (Feature)
           or else not Has_Row_Action_Dispatch (Feature)
           or else not Has_Lifecycle_Dispatch (Feature)
         then
            return False;
         end if;
      end loop;

      return True;
   end Feature_Dispatch_Covers_All_Features;

   procedure Rebuild_Active_Feature_Projection
     (S : in out Editor.State.State_Type)
   is
   begin
      case Editor.Feature_Panel.Active_Feature (S.Feature_Panel) is
         when Editor.Feature_Panel.Outline_Feature =>
            Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
         when Editor.Feature_Panel.Messages_Feature =>
            Editor.Feature_Messages.Project_Rows (S.Feature_Messages, S.Feature_Panel);
         when Editor.Feature_Panel.Search_Results_Feature =>
            Editor.Feature_Search_Results.Project_Rows
              (S.Feature_Search_Results, S.Feature_Panel);
         when Editor.Feature_Panel.Diagnostics_Feature =>
            Editor.Feature_Diagnostics.Project_Rows
              (S.Feature_Diagnostics, S.Feature_Panel);
         when Editor.Feature_Panel.Unknown_Feature =>
            Editor.Feature_Panel.Clear_Rows (S.Feature_Panel);
      end case;
   end Rebuild_Active_Feature_Projection;

   function Show_Feature
     (S       : in out Editor.State.State_Type;
      Feature : Editor.Feature_Panel.Feature_Id) return Boolean
   is
      Previous_Feature : constant Editor.Feature_Panel.Feature_Id :=
        Editor.Feature_Panel.Active_Feature (S.Feature_Panel);
      Feature_Changed : constant Boolean := Previous_Feature /= Feature;
   begin
      if not Editor.Feature_Panel.Set_Active_Feature (S.Feature_Panel, Feature) then
         return False;
      end if;
      Rebuild_Active_Feature_Projection (S);
      if Feature_Changed then
         Editor.Feature_Panel.Restore_Active_Feature_View_State (S.Feature_Panel);
      end if;
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      return Assert_Feature_Panel_State_Consistent (S);
   end Show_Feature;

   function Dispatch_Active_Feature_Clear
     (S : in out Editor.State.State_Type) return Boolean
   is
      Feature : constant Editor.Feature_Panel.Feature_Id :=
        Editor.Feature_Panel.Active_Feature (S.Feature_Panel);
   begin
      if not Editor.Feature_Panel.Feature_Can_Clear (Feature) then
         return False;
      end if;

      Editor.Feature_Panel.Forget_Feature_View_State (S.Feature_Panel, Feature);

      case Feature is
         when Editor.Feature_Panel.Outline_Feature =>
            Editor.Outline.Clear (S.Outline);
            Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
            return True;
         when Editor.Feature_Panel.Messages_Feature =>
            Editor.Feature_Messages.Clear (S.Feature_Messages);
            Editor.Feature_Messages.Reconcile_Messages_After_Row_Change
              (S.Feature_Messages, S.Feature_Panel);
            return True;
         when Editor.Feature_Panel.Search_Results_Feature =>
            Editor.Feature_Search_Results.Clear (S.Feature_Search_Results);
            Editor.Feature_Search_Results.Project_Rows
              (S.Feature_Search_Results, S.Feature_Panel);
            return True;
         when Editor.Feature_Panel.Diagnostics_Feature =>
            Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
            Editor.Feature_Diagnostics.Reconcile_Diagnostics_After_Row_Change
              (S.Feature_Diagnostics, S.Feature_Panel);
            return True;
         when Editor.Feature_Panel.Unknown_Feature =>
            return False;
      end case;
   end Dispatch_Active_Feature_Clear;

   procedure Reset_Feature_For_Buffer_Close
     (S            : in out Editor.State.State_Type;
      Feature      : Editor.Feature_Panel.Feature_Id;
      Buffer_Token : Natural)
   is
   begin
      case Feature is
         when Editor.Feature_Panel.Outline_Feature =>
            Editor.Outline.Reset_Outline_For_Buffer_Close (S.Outline, Buffer_Token);
         when Editor.Feature_Panel.Messages_Feature =>
            Editor.Feature_Messages.Reset_For_Buffer_Close
              (S.Feature_Messages, Buffer_Token);
         when Editor.Feature_Panel.Search_Results_Feature =>
            Editor.Feature_Search_Results.Reset_Search_Results_For_Buffer_Close
              (S.Feature_Search_Results, Buffer_Token);
         when Editor.Feature_Panel.Diagnostics_Feature =>
            Editor.Feature_Diagnostics.Reset_Diagnostics_For_Buffer_Close
              (S.Feature_Diagnostics, Buffer_Token);
         when Editor.Feature_Panel.Unknown_Feature =>
            null;
      end case;
   end Reset_Feature_For_Buffer_Close;

   procedure Reset_All_Features_For_Buffer_Close
     (S            : in out Editor.State.State_Type;
      Buffer_Token : Natural)
   is
   begin
      for I in 1 .. Editor.Feature_Panel.Feature_Descriptor_Count loop
         Reset_Feature_For_Buffer_Close
           (S, Editor.Feature_Panel.Descriptor_Id (I), Buffer_Token);
      end loop;
      Rebuild_Active_Feature_Projection (S);
   end Reset_All_Features_For_Buffer_Close;

   procedure Reset_Feature_For_Project_Close
     (S       : in out Editor.State.State_Type;
      Feature : Editor.Feature_Panel.Feature_Id)
   is
   begin
      case Feature is
         when Editor.Feature_Panel.Outline_Feature =>
            Editor.Outline.Reset_For_Project_Close (S.Outline);
         when Editor.Feature_Panel.Messages_Feature =>
            Editor.Feature_Messages.Reset_For_Project_Close (S.Feature_Messages);
         when Editor.Feature_Panel.Search_Results_Feature =>
            Editor.Feature_Search_Results.Reset_Search_Results_For_Project_Close
              (S.Feature_Search_Results);
         when Editor.Feature_Panel.Diagnostics_Feature =>
            Editor.Feature_Diagnostics.Reset_Diagnostics_For_Project_Close
              (S.Feature_Diagnostics);
         when Editor.Feature_Panel.Unknown_Feature =>
            null;
      end case;
   end Reset_Feature_For_Project_Close;

   procedure Reset_All_Features_For_Project_Close
     (S : in out Editor.State.State_Type)
   is
   begin
      for I in 1 .. Editor.Feature_Panel.Feature_Descriptor_Count loop
         Reset_Feature_For_Project_Close
           (S, Editor.Feature_Panel.Descriptor_Id (I));
      end loop;
      Editor.Feature_Panel.Reset_For_Project_Close (S.Feature_Panel);
   end Reset_All_Features_For_Project_Close;

   procedure Reset_Feature_For_Workspace_Close
     (S       : in out Editor.State.State_Type;
      Feature : Editor.Feature_Panel.Feature_Id)
   is
   begin
      Editor.Feature_Panel.Forget_Feature_View_State (S.Feature_Panel, Feature);

      case Feature is
         when Editor.Feature_Panel.Outline_Feature =>
            Editor.Outline.Clear (S.Outline);
         when Editor.Feature_Panel.Messages_Feature =>
            Editor.Feature_Messages.Reset_For_Workspace_Close (S.Feature_Messages);
         when Editor.Feature_Panel.Search_Results_Feature =>
            Editor.Feature_Search_Results.Reset_Search_Results_For_Workspace_Close
              (S.Feature_Search_Results);
         when Editor.Feature_Panel.Diagnostics_Feature =>
            Editor.Feature_Diagnostics.Reset_Diagnostics_For_Workspace_Close
              (S.Feature_Diagnostics);
         when Editor.Feature_Panel.Unknown_Feature =>
            null;
      end case;
   end Reset_Feature_For_Workspace_Close;

   procedure Reset_All_Features_For_Workspace_Close
     (S : in out Editor.State.State_Type)
   is
   begin
      for I in 1 .. Editor.Feature_Panel.Feature_Descriptor_Count loop
         Reset_Feature_For_Workspace_Close
           (S, Editor.Feature_Panel.Descriptor_Id (I));
      end loop;
      Editor.Feature_Panel.Clear (S.Feature_Panel);
   end Reset_All_Features_For_Workspace_Close;

   function Assert_Feature_Panel_State_Consistent
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Feature_Panel.Invariant_Holds (S.Feature_Panel)
        and then Editor.Feature_Panel.Is_Known_Feature
          (Editor.Feature_Panel.Active_Feature (S.Feature_Panel));
   end Assert_Feature_Panel_State_Consistent;

end Editor.Feature_Panel_Controller;
