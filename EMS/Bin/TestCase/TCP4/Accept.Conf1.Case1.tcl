#
# The material contained herein is not a license, either      
# expressly or impliedly, to any intellectual property owned  
# or controlled by any of the authors or developers of this   
# material or to any contribution thereto. The material       
# contained herein is provided on an "AS IS" basis and, to the
# maximum extent permitted by applicable law, this information
# is provided AS IS AND WITH ALL FAULTS, and the authors and  
# developers of this material hereby disclaim all other       
# warranties and conditions, either express, implied or       
# statutory, including, but not limited to, any (if any)      
# implied warranties, duties or conditions of merchantability,
# of fitness for a particular purpose, of accuracy or         
# completeness of responses, of results, of workmanlike       
# effort, of lack of viruses and of lack of negligence, all   
# with regard to this material and any contribution thereto.  
# Designers must not rely on the absence or characteristics of
# any features or instructions marked "reserved" or           
# "undefined." The Unified EFI Forum, Inc. reserves any       
# features or instructions so marked for future definition and
# shall have no responsibility whatsoever for conflicts or    
# incompatibilities arising from future changes to them. ALSO,
# THERE IS NO WARRANTY OR CONDITION OF TITLE, QUIET ENJOYMENT,
# QUIET POSSESSION, CORRESPONDENCE TO DESCRIPTION OR          
# NON-INFRINGEMENT WITH REGARD TO THE TEST SUITE AND ANY      
# CONTRIBUTION THERETO.                                       
#                                                             
# IN NO EVENT WILL ANY AUTHOR OR DEVELOPER OF THIS MATERIAL OR
# ANY CONTRIBUTION THERETO BE LIABLE TO ANY OTHER PARTY FOR   
# THE COST OF PROCURING SUBSTITUTE GOODS OR SERVICES, LOST    
# PROFITS, LOSS OF USE, LOSS OF DATA, OR ANY INCIDENTAL,      
# CONSEQUENTIAL, DIRECT, INDIRECT, OR SPECIAL DAMAGES WHETHER 
# UNDER CONTRACT, TORT, WARRANTY, OR OTHERWISE, ARISING IN ANY
# WAY OUT OF THIS OR ANY OTHER AGREEMENT RELATING TO THIS     
# DOCUMENT, WHETHER OR NOT SUCH PARTY HAD ADVANCE NOTICE OF   
# THE POSSIBILITY OF SUCH DAMAGES.                            
#                                                             
# Copyright 2006, 2007, 2008, 2009, 2010 Unified EFI, Inc. All
# Rights Reserved, subject to all existing rights in all      
# matters included within this Test Suite, to which United    
# EFI, Inc. makes no claim of right.                          
#                                                             
# Copyright (c) 2010, Intel Corporation. All rights reserved.<BR> 
#
#
################################################################################
CaseLevel         CONFORMANCE
CaseAttribute     AUTO
CaseVerboseLevel  DEFAULT

#
# test case Name, category, description, GUID...
#
CaseGuid          01E0F38A-45DF-4662-925F-6B89AD6C3B74
CaseName          Accept.Conf1.Case1
CaseCategory      TCP
CaseDescription   {This case is to test the conformance - EFI_NOT_STARTED.     \
                  -- This EFI TCPv4 Protocol instance has not been configured.}
################################################################################

Include TCP4/include/Tcp4.inc.tcl

proc CleanUpEutEnvironment {} {
  DestroyTcb
  DelEntryInArpCache

  Tcp4ServiceBinding->DestroyChild "@R_Handle, &@R_Status"
  GetAck

  BS->CloseEvent "@R_Accept_CompletionToken.Event, &@R_Status"
  GetAck
  EndLogPacket
  EndScope _TCP4_SPEC_CONFORMANCE_
  EndLog
}

#
# Begin log ...
#
BeginLog


#
# BeginScope
#
BeginScope _TCP4_SPEC_CONFORMANCE_

BeginLogPacket Accept.Conf1.Case1 "host $DEF_EUT_IP_ADDR and host              \
                                             $DEF_ENTS_IP_ADDR"
#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
UINTN                            R_Status
UINTN                            R_Handle
UINTN                            R_Context

EFI_TCP4_CONFIG_DATA             R_Tcp4ConfigData
EFI_IP4_MODE_DATA                R_Ip4ModeData
EFI_MANAGED_NETWORK_CONFIG_DATA  R_MnpConfigData
EFI_SIMPLE_NETWORK_MODE          R_SnpModeData

EFI_TCP4_LISTEN_TOKEN            R_Accept_ListenToken
EFI_TCP4_COMPLETION_TOKEN        R_Accept_CompletionToken

#
# Initialization of TCB related on OS side.
#
CreateTcb TCB $DEF_ENTS_IP_ADDR $DEF_ENTS_PRT $DEF_EUT_IP_ADDR $DEF_EUT_PRT

LocalEther  $DEF_ENTS_MAC_ADDR
RemoteEther $DEF_EUT_MAC_ADDR
LocalIp     $DEF_ENTS_IP_ADDR
RemoteIp    $DEF_EUT_IP_ADDR

#
# Add an entry in ARP cache.
#
AddEntryInArpCache

#
# Create Tcp4 Child.
#
Tcp4ServiceBinding->CreateChild "&@R_Handle, &@R_Status"
GetAck
SetVar     [subst $ENTS_CUR_CHILD]  @R_Handle
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp4SBP.CreateChild - Create Child 1"                         \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

set L_TcpFlag [expr $SYN]
UpdateTcpSendBuffer TCB -c $L_TcpFlag
SendTcpPacket TCB

#
# Check Point: Call Tcp4.Accept(), without previous configuration.
#
BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_Context,        \
                 &@R_Accept_CompletionToken.Event, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.CreateEvent."                                              \
                "ReturnStatus - $R_Status,ExpectedStatus - $EFI_SUCCESS"

SetVar R_Accept_ListenToken.CompletionToken @R_Accept_CompletionToken

Tcp4->Accept {&@R_Accept_ListenToken, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_NOT_STARTED]
RecordAssertion $assert $Tcp4AcceptConf1AssertionGuid001                       \
                "Tcp4.Accept - Call Accept() without configuration."           \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_NOT_STARTED"

#
# Clean up the environment on EUT side.
#
CleanUpEutEnvironment
