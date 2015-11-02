/*++
  The material contained herein is not a license, either        
  expressly or impliedly, to any intellectual property owned    
  or controlled by any of the authors or developers of this     
  material or to any contribution thereto. The material         
  contained herein is provided on an "AS IS" basis and, to the  
  maximum extent permitted by applicable law, this information  
  is provided AS IS AND WITH ALL FAULTS, and the authors and    
  developers of this material hereby disclaim all other         
  warranties and conditions, either express, implied or         
  statutory, including, but not limited to, any (if any)        
  implied warranties, duties or conditions of merchantability,  
  of fitness for a particular purpose, of accuracy or           
  completeness of responses, of results, of workmanlike         
  effort, of lack of viruses and of lack of negligence, all     
  with regard to this material and any contribution thereto.    
  Designers must not rely on the absence or characteristics of  
  any features or instructions marked "reserved" or             
  "undefined." The Unified EFI Forum, Inc. reserves any         
  features or instructions so marked for future definition and  
  shall have no responsibility whatsoever for conflicts or      
  incompatibilities arising from future changes to them. ALSO,  
  THERE IS NO WARRANTY OR CONDITION OF TITLE, QUIET ENJOYMENT,  
  QUIET POSSESSION, CORRESPONDENCE TO DESCRIPTION OR            
  NON-INFRINGEMENT WITH REGARD TO THE TEST SUITE AND ANY        
  CONTRIBUTION THERETO.                                         
                                                                
  IN NO EVENT WILL ANY AUTHOR OR DEVELOPER OF THIS MATERIAL OR  
  ANY CONTRIBUTION THERETO BE LIABLE TO ANY OTHER PARTY FOR     
  THE COST OF PROCURING SUBSTITUTE GOODS OR SERVICES, LOST      
  PROFITS, LOSS OF USE, LOSS OF DATA, OR ANY INCIDENTAL,        
  CONSEQUENTIAL, DIRECT, INDIRECT, OR SPECIAL DAMAGES WHETHER   
  UNDER CONTRACT, TORT, WARRANTY, OR OTHERWISE, ARISING IN ANY  
  WAY OUT OF THIS OR ANY OTHER AGREEMENT RELATING TO THIS       
  DOCUMENT, WHETHER OR NOT SUCH PARTY HAD ADVANCE NOTICE OF     
  THE POSSIBILITY OF SUCH DAMAGES.                              
                                                                
  Copyright 2006 - 2014 Unified EFI, Inc. All  
  Rights Reserved, subject to all existing rights in all        
  matters included within this Test Suite, to which United      
  EFI, Inc. makes no claim of right.                            
                                                                
  Copyright (c) 2010 - 2014, Intel Corporation. All rights reserved.<BR>   
   
--*/
/*++

Module Name:

  lock.c

Abstract:

  Implements SCT_LOCK

--*/

#include "SctLibInternal.h"

/*++

Routine Description:

  Initialize a basic mutual exclusion lock.   Each lock
  provides mutual exclusion access at it's task priority
  level.  Since there is no-premption (at any TPL) or
  multiprocessor support, acquiring the lock only consists
  of raising to the locks TPL.

  Note on a debug build the lock is acquired and released
  to help ensure proper usage.

Arguments:

  Lock        - The SCT_LOCK structure to initialize

  Priority    - The task priority level of the lock


Returns:

  An initialized F Lock structure.

--*/
VOID
SctInitializeLock (
  IN OUT SCT_LOCK    *Lock,
  IN EFI_TPL      Priority
  )
{
  Lock->Tpl = Priority;
  Lock->OwnerTpl = 0;
  Lock->Lock = 0;
}

/*++

Routine Description:

  Raising to the task priority level of the mutual exclusion
  lock, and then acquires ownership of the lock.

Arguments:

  Lock        - The lock to acquire

Returns:

  Lock owned

--*/
VOID
SctAcquireLock (
  IN SCT_LOCK    *Lock
  )
{
  if (tBS) {
    if (tBS->RaiseTPL != NULL) {
      Lock->OwnerTpl = tBS->RaiseTPL (Lock->Tpl);
    }
  } else {
    // Unsupported
    ASSERT(0);
  }
  Lock->Lock += 1;
  ASSERT (Lock->Lock == 1);
}

/*++

Routine Description:

  Releases ownership of the mutual exclusion lock, and
  restores the previous task priority level.

Arguments:

  Lock        - The lock to release

Returns:

  Lock unowned

--*/
VOID
SctReleaseLock (
  IN SCT_LOCK    *Lock
  )
{
  EFI_TPL     Tpl;

  Tpl = Lock->OwnerTpl;
  ASSERT(Lock->Lock == 1);
  Lock->Lock -= 1;
  if (tBS) {
    if (tBS->RestoreTPL != NULL) {
      tBS->RestoreTPL (Tpl);
    }
  } else {
    // Unsupported
    ASSERT(0);
  }
}

EFI_STATUS
SctAcquireLockOrFail (
  IN SCT_LOCK  *Lock
  )
{
  if (Lock->Lock != 0) {
    //
    // Lock is already owned, so bail out
    //
    return EFI_ACCESS_DENIED;
  }

  if (tBS) {
    if (tBS->RestoreTPL != NULL) {
      Lock->OwnerTpl = tBS->RaiseTPL (Lock->Tpl);
    }
  } else {
    // Unsupported
    ASSERT(0);
  }

  Lock->Lock += 1;
  return EFI_SUCCESS;
}
