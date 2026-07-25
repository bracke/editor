with Editor.Commands.Audit_Model; use Editor.Commands.Audit_Model;
package Editor.Commands.Audits is

   function Has_Command_Reference
     (Id : Command_Id) return Boolean;

   function File_Lifecycle_Command_Reference_Coherent return Boolean;

   function Has_Discoverability_Metadata
     (Id : Command_Id) return Boolean;

   function Command_Discoverability_Coherent return Boolean;

   function Descriptor_Is_Complete
     (Id : Command_Id) return Boolean;

   procedure Audit_Command
     (Id      : Command_Id;
      Failure : out Command_Audit_Failure;
      Found   : out Boolean);

   function Audit_Command_Registry
      return Command_Audit_Failure_Vectors.Vector;

   function Command_Audit_Summary
     (Failures : Command_Audit_Failure_Vectors.Vector) return String;

end Editor.Commands.Audits;
