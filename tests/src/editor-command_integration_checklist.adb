with AUnit.Assertions; use AUnit.Assertions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands;

package body Editor.Command_Integration_Checklist is

   function Prefix (Id : Editor.Commands.Command_Id) return String is
   begin
      return Editor.Commands.Command_Id'Image (Id) & ": ";
   end Prefix;

   procedure Assert_Ready_For_User_Command
     (Id : Editor.Commands.Command_Id)
   is
      Failure : Editor.Commands.Command_Audit_Failure;
      Found   : Boolean := False;
      D       : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Id);
   begin
      Assert (Editor.Commands.Is_Concrete_Command (Id),
              Prefix (Id) & "command id is not concrete");
      Assert (Editor.Commands.Has_Descriptor (Id),
              Prefix (Id) & "missing descriptor");
      Assert (Editor.Commands.Descriptor_Is_Complete (Id),
              Prefix (Id) & "descriptor is incomplete");
      Assert (Length (D.Name) > 0,
              Prefix (Id) & "missing user-facing label");
      Assert (Length (D.Description) > 0,
              Prefix (Id) & "missing description");
      Assert (Editor.Commands.Has_Availability_Handler (Id),
              Prefix (Id) & "missing availability handler coverage");
      Editor.Commands.Audit_Command (Id, Failure, Found);
      Assert (not Found,
              Prefix (Id) & "audit failure " &
              Editor.Commands.Command_Audit_Failure_Kind'Image (Failure.Kind));
   end Assert_Ready_For_User_Command;

   procedure Assert_Ready_For_Bindable_Command
     (Id : Editor.Commands.Command_Id)
   is
   begin
      Assert_Ready_For_User_Command (Id);
      Assert (Editor.Commands.Is_Bindable_Command (Id),
              Prefix (Id) & "command is not bindable");
      Assert (Editor.Commands.Has_Stable_Name (Id),
              Prefix (Id) & "bindable command has no stable command name");
   end Assert_Ready_For_Bindable_Command;

   procedure Assert_Ready_For_Destructive_Command
     (Id : Editor.Commands.Command_Id)
   is
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Id);
   begin
      Assert_Ready_For_User_Command (Id);
      Assert (D.Destructive,
              Prefix (Id) & "destructive command missing destructive classification");
   end Assert_Ready_For_Destructive_Command;

   procedure Assert_Ready_For_Configuration_Command
     (Id : Editor.Commands.Command_Id)
   is
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Id);
   begin
      Assert_Ready_For_User_Command (Id);
      Assert (D.Configuration,
              Prefix (Id) & "configuration command missing configuration classification");
   end Assert_Ready_For_Configuration_Command;

   procedure Assert_Ready_For_Lifecycle_Command
     (Id : Editor.Commands.Command_Id)
   is
      D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Id);
   begin
      Assert_Ready_For_User_Command (Id);
      Assert (D.Lifecycle,
              Prefix (Id) & "lifecycle command missing lifecycle classification");
   end Assert_Ready_For_Lifecycle_Command;

end Editor.Command_Integration_Checklist;
