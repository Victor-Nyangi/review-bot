<?php

namespace App\Policies;

use App\Models\Invoice;
use App\Models\User;

class InvoicePolicy
{
    public function view(User $user, Invoice $invoice): bool
    {
        return $user->school_id === $invoice->school_id;
    }

    public function update(User $user, Invoice $invoice): bool
    {
        return $user->school_id === $invoice->school_id && $user->hasRole('bursar');
    }

    public function delete(User $user, Invoice $invoice): bool
    {
        return $this->update($user, $invoice) && $invoice->status === 'draft';
    }
}
