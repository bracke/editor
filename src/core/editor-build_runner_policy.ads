package Editor.Build_Runner_Policy is

   --  Phase 504 public build execution policy.  This is transient runtime
   --  configuration only: it is not supplied by the Command Palette,
   --  keybindings, persisted workspace/settings/recent-project data, or public
   --  build UI request state.
   type Build_Execution_Policy is
     (Build_Execution_Disabled,
      Build_Execution_Stub_Only,
      Build_Execution_Bounded_Process);

   --  Phase 509 timeout policy classification.  Timeout values remain runtime
   --  runner policy only and are never supplied by shell text, palette query,
   --  keybinding payloads, workspace/session state, settings, or build history.
   type Build_Timeout_Policy is
     (Build_Timeout_Disabled_For_Tests_Only,
      Build_Timeout_Default_Bounded,
      Build_Timeout_Explicit_Bounded);

   type Build_Timeout_Source is
     (Timeout_Source_Default_Runtime_Policy,
      Timeout_Source_Test_Fixture,
      Timeout_Source_Explicit_Build_Policy);

   type Build_Cancellation_State is
     (No_Cancellation_Requested,
      Cancellation_Requested,
      Cancellation_Acknowledged,
      Cancellation_Unsupported);

end Editor.Build_Runner_Policy;
