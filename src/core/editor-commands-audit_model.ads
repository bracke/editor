with Editor.Command_Ids; use Editor.Command_Ids;
with Ada.Containers.Vectors;

package Editor.Commands.Audit_Model is

   type Command_Audit_Failure_Kind is
     (Missing_Descriptor,
      Missing_Label,
      Missing_Description,
      Missing_Category,
      Missing_Stable_Name,
      Duplicate_Stable_Name,
      Missing_Availability,
      Missing_Executor_Handling,
      Invalid_Bindability,
      Invalid_Default_Keybinding,
      Missing_Classification,
      Ambiguous_Save_Command,
      Route_Bypasses_Executor,
      Unexpected_Domain_Mutation);

   type Command_Audit_Failure is record
      Kind    : Command_Audit_Failure_Kind := Missing_Descriptor;
      Command : Command_Id := No_Command;
   end record;

   package Command_Audit_Failure_Vectors is new
     Ada.Containers.Vectors
       (Index_Type   => Natural,
        Element_Type => Command_Audit_Failure);

end Editor.Commands.Audit_Model;
