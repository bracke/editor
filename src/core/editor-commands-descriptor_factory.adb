with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Commands.Descriptor_Factory is

   function Make_Command_Descriptor
     (Id             : Command_Id;
      Stable_Name    : String;
      Label          : String;
      Description    : String;
      Category       : Command_Category;
      Visible        : Boolean;
      Bindable       : Boolean;
      Destructive    : Boolean := False;
      Lifecycle      : Boolean := False;
      Configuration  : Boolean := False)
      return Command_Descriptor
   is
      pragma Unreferenced (Stable_Name);
   begin
      return
        (Id            => Id,
         Name          => To_Unbounded_String (Label),
         Description   => To_Unbounded_String (Description),
         Category      => Category,
         Visibility    => (if Visible then Palette_Command else Hidden_Command),
         Bindable      => Bindable,
         Destructive   => Destructive,
         Lifecycle     => Lifecycle,
         Configuration => Configuration,
         Summary       => To_Unbounded_String (Command_Summary (Id)),
         Availability_Summary => To_Unbounded_String (Command_Availability_Summary (Id)),
         Mutation_Summary => To_Unbounded_String (Command_Mutation_Summary (Id)),
         Filesystem_Effect_Summary => To_Unbounded_String (Command_Filesystem_Effect_Summary (Id)),
         State_Preservation_Summary => To_Unbounded_String (Command_State_Preservation_Summary (Id)),
         Non_Goal_Summary => To_Unbounded_String (Command_Non_Goal_Summary (Id)),
         Requires_Explicit_Target => Command_Requires_Explicit_Target (Id),
         Target_Prompt_Capable => Command_Is_Target_Prompt_Capable (Id),
         Target_Prompt_Label => To_Unbounded_String (Command_Target_Prompt_Label (Id)),
         Family        => Command_Family (Id),
         Effect_Classification => Command_Effect_Classification (Id));
   end Make_Command_Descriptor;


end Editor.Commands.Descriptor_Factory;
