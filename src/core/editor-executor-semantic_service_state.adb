with Editor.Ada_Language_Service;

package body Editor.Executor.Semantic_Service_State is

   function Current_Language_Service
     (S : Editor.State.State_Type)
      return Editor.Ada_Language_Service.Service_State
   is
      Service_Status : constant Editor.Ada_Language_Service.Index_Status :=
        Editor.Ada_Language_Service.Status (S.Language_Service);
      Index_Status : constant Editor.Ada_Language_Service.Index_Status :=
        Editor.Ada_Language_Service.Status (S.Language_Index);
   begin
      if Service_Status.File_Count = Index_Status.File_Count
        and then Service_Status.Unit_Count = Index_Status.Unit_Count
        and then Service_Status.Symbol_Count = Index_Status.Symbol_Count
        and then Service_Status.Fingerprint = Index_Status.Fingerprint
        and then Service_Status.Overflowed = Index_Status.Overflowed
      then
         return S.Language_Service;
      end if;

      return Editor.Ada_Language_Service.From_Index (S.Language_Index);
   end Current_Language_Service;

   procedure Ensure_Current_Language_Service
     (S : in out Editor.State.State_Type)
   is
      Service_Status : constant Editor.Ada_Language_Service.Index_Status :=
        Editor.Ada_Language_Service.Status (S.Language_Service);
      Index_Status : constant Editor.Ada_Language_Service.Index_Status :=
        Editor.Ada_Language_Service.Status (S.Language_Index);
   begin
      if Service_Status.File_Count /= Index_Status.File_Count
        or else Service_Status.Unit_Count /= Index_Status.Unit_Count
        or else Service_Status.Symbol_Count /= Index_Status.Symbol_Count
        or else Service_Status.Fingerprint /= Index_Status.Fingerprint
        or else Service_Status.Overflowed /= Index_Status.Overflowed
      then
         Editor.Ada_Language_Service.Put_Index
           (S.Language_Service, S.Language_Index);
      end if;
   end Ensure_Current_Language_Service;

end Editor.Executor.Semantic_Service_State;
