package Editor.Commands.Reference_Metadata is

   function File_Lifecycle_Target_Prompt_Metadata_Minimal return Boolean;

   function File_Lifecycle_Target_Prompt_Metadata_Canonical_And_Minimal
     return Boolean;

   function File_Lifecycle_Target_Prompt_Metadata_Frozen return Boolean;

   function Reference_Summary
     (Id : Command_Id) return String;

   function Reference_Availability_Summary
     (Id : Command_Id) return String;

   function Reference_Mutation_Summary
     (Id : Command_Id) return String;

   function Reference_Filesystem_Effect_Summary
     (Id : Command_Id) return String;

   function Reference_State_Preservation_Summary
     (Id : Command_Id) return String;

   function Reference_Non_Goal_Summary
     (Id : Command_Id) return String;

   function Reference_Command_Family
     (Id : Command_Id) return Command_Family_Id;

   function Reference_Effect_Classification
     (Id : Command_Id) return Command_Effect_Classification_Id;

   function Command_Requires_Explicit_Target
     (Id : Command_Id) return Boolean;

   function Command_Is_Target_Prompt_Capable
     (Id : Command_Id) return Boolean;

   function Command_Target_Prompt_Label
     (Id : Command_Id) return String;

   function Command_Summary
     (Id : Command_Id) return String;

   function Command_Availability_Summary
     (Id : Command_Id) return String;

   function Command_Mutation_Summary
     (Id : Command_Id) return String;

   function Command_Filesystem_Effect_Summary
     (Id : Command_Id) return String;

   function Command_State_Preservation_Summary
     (Id : Command_Id) return String;

   function Command_Non_Goal_Summary
     (Id : Command_Id) return String;

   function Command_Family
     (Id : Command_Id) return Command_Family_Id;

   function Command_Family_Label
     (Family : Command_Family_Id) return String;

   function Command_Effect_Classification
     (Id : Command_Id) return Command_Effect_Classification_Id;

   function Command_Effect_Classification_Label
     (Effect : Command_Effect_Classification_Id) return String;

end Editor.Commands.Reference_Metadata;
