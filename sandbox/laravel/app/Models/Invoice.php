<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * A fee invoice issued by a school to one student.
 *
 * @property int $id
 * @property int $school_id
 * @property int $student_id
 * @property int $amount   minor units (cents)
 * @property string $status draft|issued|paid|void
 */
class Invoice extends Model
{
    protected $guarded = [];

    protected $casts = [
        'amount' => 'integer',
        'due_on' => 'date',
    ];

    public function school(): BelongsTo
    {
        return $this->belongsTo(School::class);
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }
}
