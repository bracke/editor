with Editor.Workspace_Persistence;
with Ada.Strings.Unbounded;

package Editor.Workspace_Persistence.Audits is

   function Audit_Serialized_Buffer_Persistence
     (Serialized_Workspace : String) return Workspace_Buffer_Persistence_Audit;

   function Audit_Buffer_Persistence
     (Snapshot : Workspace_Snapshot) return Workspace_Buffer_Persistence_Audit;

   function Restore_Details_Label
     (Summary : Workspace_Restore_Summary) return String;

   function Audit_Restore_Roundtrip
     (Before  : Workspace_Snapshot;
      After   : Workspace_Snapshot;
      Summary : Workspace_Restore_Summary) return Workspace_Restore_Audit;


end Editor.Workspace_Persistence.Audits;
